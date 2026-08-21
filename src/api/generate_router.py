from typing import Optional
import os
import time
from urllib.parse import quote
from fastapi import APIRouter, HTTPException, Query, Request
from fastapi.responses import FileResponse, StreamingResponse
from fastapi.templating import Jinja2Templates
from src.services.docx_service import CustomDocxService
from src.services.storage_service import CaseStorageService, PersonStorageService, CustomDocStorageService

router = APIRouter(prefix="/api/v1/generate", tags=["Document Generation"])
custom_docx_service = CustomDocxService()
case_storage = CaseStorageService()
person_storage = PersonStorageService()
custom_doc_storage = CustomDocStorageService()

TEMPLATES_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "templates")
templates = Jinja2Templates(directory=TEMPLATES_DIR)


# ==============================================================================
# CÁC API QUẢN LÝ VÀ XUẤT VĂN BẢN (CUSTOM DOCUMENTS)
# ==============================================================================

@router.get("/templates/custom/{level}", summary="Lấy danh sách các mẫu văn bản tùy biến theo cấp độ (case / person)")
async def get_custom_templates(level: str):
    """
    Trả về danh sách các mẫu văn bản từ custom_templates/{level}/metadata.json
    """
    if level not in ["case", "person"]:
        raise HTTPException(status_code=400, detail="Cấp độ mẫu văn bản không hợp lệ (phải là case hoặc person)")
    return custom_docx_service.get_templates(level=level)


@router.get("/templates/custom/{level}/{template_filename}/layout", summary="Bóc tách cấu trúc bố cục DOCX tương tác")
async def get_custom_template_layout(
    level: str,
    template_filename: str
):
    """
    Trả về cấu trúc cây phần tử (đoạn văn, bảng biểu, căn lề, biến Jinja2) của file Word mẫu
    để hiển thị tờ giấy A4 tương tác trên giao diện người dùng.
    """
    try:
        return custom_docx_service.get_template_layout(template_filename=template_filename, level=level)
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi bóc tách layout docx: {str(e)}")


@router.get("/custom/{case_id}/{doc_id}/pdf-data", summary="Lấy luồng dữ liệu PDF văn bản để PDF.js render")
async def get_custom_pdf_data(
    case_id: str,
    doc_id: str,
    person_id: Optional[str] = Query(None, description="ID của cá nhân nếu là văn bản cấp cá nhân"),
    force: bool = Query(False, description="Bắt buộc render lại và bỏ qua cache"),
):
    """
    Kết xuất file Word và chuyển sang PDF (có Cache), trả về stream nhị phân application/octet-stream.
    """
    case = case_storage.get_case(case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Không tìm thấy vụ việc")

    custom_doc = custom_doc_storage.get_custom_doc(case_id, doc_id, person_id=person_id)
    if not custom_doc:
        raise HTTPException(status_code=404, detail="Không tìm thấy văn bản trong dữ liệu")

    person = None
    level = "case"
    if person_id:
        person = person_storage.get_person(case_id, person_id)
        level = "person"

    try:
        pdf_path = custom_docx_service.generate_pdf(
            template_filename=custom_doc.template_file,
            custom_doc=custom_doc,
            case_data=case,
            person_data=person,
            level=level,
            force=force
        )
        headers = {
            "Content-Disposition": "inline; filename=preview.bin",
        }
        if not force:
            headers["Cache-Control"] = "public, max-age=86400"
        else:
            headers["Cache-Control"] = "no-cache, no-store, must-revalidate, max-age=0"
            headers["Pragma"] = "no-cache"

        return FileResponse(
            pdf_path,
            media_type="application/octet-stream",
            headers=headers
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi tạo tài liệu PDF: {str(e)}")


@router.get("/custom/{case_id}/{doc_id}/preview-viewer", summary="Trang HTML xem trước tài liệu PDF qua PDF.js Canvas")
async def get_custom_preview_viewer(
    request: Request,
    case_id: str,
    doc_id: str,
    person_id: Optional[str] = Query(None, description="ID của cá nhân nếu có"),
    force: bool = Query(False, description="Bắt buộc render lại và bỏ qua cache"),
    t: Optional[str] = Query(None, description="Timestamp tránh cache")
):
    """
    Trả về giao diện Web sử dụng Mozilla PDF.js vẽ từng trang A4 lên HTML5 Canvas.
    """
    cur_time = t or str(int(time.time() * 1000))
    person_param = f"&person_id={person_id}" if person_id else ""
    force_param = f"&force=true&t={cur_time}" if force else f"&t={cur_time}"
    pdf_data_url = f"/api/v1/generate/custom/{case_id}/{doc_id}/pdf-data?{person_param.lstrip('&')}{force_param}"

    return templates.TemplateResponse(
        request=request,
        name="preview_viewer.html",
        context={
            "pdf_data_url": pdf_data_url,
            "force": force
        }
    )


@router.post("/custom/{case_id}/{doc_id}/download", summary="Tải file Word của văn bản")
async def download_custom_docx(
    case_id: str,
    doc_id: str,
    person_id: Optional[str] = Query(None, description="ID của cá nhân nếu có")
):
    case = case_storage.get_case(case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Không tìm thấy vụ việc")

    custom_doc = custom_doc_storage.get_custom_doc(case_id, doc_id, person_id=person_id)
    if not custom_doc:
        raise HTTPException(status_code=404, detail="Không tìm thấy văn bản trong vụ việc")

    person = None
    level = "case"
    if person_id:
        person = person_storage.get_person(case_id, person_id)
        level = "person"

    try:
        buffer = custom_docx_service.generate_docx_bytes(
            template_filename=custom_doc.template_file,
            custom_doc=custom_doc,
            case_data=case,
            person_data=person,
            level=level
        )
        templates_list = custom_docx_service.get_templates(level=level)
        matched = [tpl["display_name"] for tpl in templates_list if tpl.get("file_name") == custom_doc.template_file]
        display_tpl_name = matched[0] if matched else custom_doc.template_file.replace(".docx", "")
        safe_title = custom_doc.title.strip() if custom_doc.title.strip() else "VanBan"
        download_filename = f"{display_tpl_name} - {safe_title}.docx"

        encoded_filename = quote(download_filename)
        safe_ascii_filename = custom_doc.template_file.replace(".docx", "")
        headers = {
            "Content-Disposition": f"attachment; filename=\"{safe_ascii_filename}\"; filename*=UTF-8''{encoded_filename}"
        }

        return StreamingResponse(
            buffer,
            media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            headers=headers
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi tạo tài liệu Word: {str(e)}")