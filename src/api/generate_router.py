from typing import Optional
import os
import time
from urllib.parse import quote
from fastapi import APIRouter, HTTPException, Query, Request
from fastapi.responses import FileResponse, StreamingResponse
from fastapi.templating import Jinja2Templates
from src.services.docx_service import PersonDocxService, CaseDocxService, CustomDocxService
from src.services.storage_service import CaseStorageService, PersonStorageService, CustomDocStorageService


router = APIRouter(prefix="/api/v1/generate", tags=["Document Generation"])
person_docx_service = PersonDocxService()
case_docx_service = CaseDocxService()
custom_docx_service = CustomDocxService()
case_storage = CaseStorageService()
person_storage = PersonStorageService()
custom_doc_storage = CustomDocStorageService()

TEMPLATES_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "templates")
templates = Jinja2Templates(directory=TEMPLATES_DIR)


# ==============================================================================
# 1. CÁC API XUẤT VĂN BẢN CẤP ĐỐI TƯỢNG / CÁ NHÂN (PERSON LEVEL)
# ==============================================================================

@router.get("/templates/person", summary="Lấy danh sách các mẫu văn bản dành cho cá nhân")
async def get_person_templates():
    """
    Trả về danh sách các mẫu văn bản từ thư mục templates/person/metadata.json
    """
    return person_docx_service.get_templates()

@router.get("/person/{case_id}/{person_id}/pdf-data", summary="Lấy luồng dữ liệu PDF cá nhân để PDF.js render")
async def get_person_pdf_data(
    case_id: str,
    person_id: str,
    template_file: str = Query("ly-lich-ca-nhan.docx", description="Tên file mẫu docx"),
    force: bool = Query(False, description="Bắt buộc render lại và bỏ qua cache"),
):
    """
    Kết xuất file Word cá nhân và chuyển sang PDF (có Cache), trả về stream nhị phân application/octet-stream
    kèm Cache-Control để phản hồi ngay lập tức trong 0ms.
    """
    person = person_storage.get_person(case_id, person_id)
    if not person:
        raise HTTPException(status_code=404, detail="Không tìm thấy thông tin cá nhân trong vụ việc")

    try:
        pdf_path = person_docx_service.generate_pdf(
            template_filename=template_file,
            person_data=person,
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
        raise HTTPException(status_code=500, detail=f"Lỗi tạo tài liệu PDF cá nhân: {str(e)}")

@router.get("/person/{case_id}/{person_id}/preview-viewer", summary="Trang HTML xem trước tài liệu PDF cá nhân qua PDF.js Canvas")
async def get_person_preview_viewer(
    request: Request,
    case_id: str,
    person_id: str,
    template_file: str = Query("209_ly_lich_ca_nhan.docx", description="Tên file mẫu docx"),
    force: bool = Query(False, description="Bắt buộc render lại và bỏ qua cache"),
    t: Optional[str] = Query(None, description="Timestamp tránh cache")
):
    """
    Trả về giao diện Web sử dụng Mozilla PDF.js vẽ từng trang A4 lên HTML5 Canvas cho cá nhân.
    """
    encoded_tpl_name = quote(template_file)
    cur_time = t or str(int(time.time() * 1000))
    force_param = f"&force=true&t={cur_time}" if force else f"&t={cur_time}"
    pdf_data_url = f"/api/v1/generate/person/{case_id}/{person_id}/pdf-data?template_file={encoded_tpl_name}{force_param}"

    return templates.TemplateResponse(
        request=request,
        name="preview_viewer.html",
        context={
            "pdf_data_url": pdf_data_url,
            "force": force
        }
    )

@router.post("/person/{case_id}/{person_id}/download", summary="Tải file Word cá nhân theo template")
async def download_person_docx(
    case_id: str,
    person_id: str,
    template_file: str = Query("209_ly_lich_ca_nhan.docx", description="Tên file mẫu docx")
):
    person = person_storage.get_person(case_id, person_id)
    if not person:
        raise HTTPException(status_code=404, detail="Không tìm thấy thông tin cá nhân trong vụ việc")

    try:
        buffer = person_docx_service.generate_docx_bytes(
            template_filename=template_file,
            person_data=person
        )
        templates_list = person_docx_service.get_templates()
        matched = [tpl["display_name"] for tpl in templates_list if tpl.get("file_name") == template_file]
        display_tpl_name = matched[0] if matched else template_file.replace(".docx", "")
        safe_person_name = person.ho_ten.strip() if person.ho_ten.strip() else "Không tên"
        download_filename = f"{display_tpl_name} - {safe_person_name}.docx"

        encoded_filename = quote(download_filename)
        safe_ascii_filename = template_file.replace(".docx", "")
        headers = {
            "Content-Disposition": f"attachment; filename=\"{safe_ascii_filename}\"; filename*=UTF-8''{encoded_filename}"
        }

        return StreamingResponse(
            buffer,
            media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            headers=headers
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi tạo tài liệu Word cá nhân: {str(e)}")


# ==============================================================================
# 2. CÁC API XUẤT VĂN BẢN CẤP VỤ ÁN / VỤ VIỆC (CASE LEVEL)
# ==============================================================================

@router.get("/templates/case", summary="Lấy danh sách các mẫu văn bản dành cho vụ án")
async def get_case_templates():
    """
    Trả về danh sách các mẫu văn bản từ thư mục templates/case/metadata.json
    """
    return case_docx_service.get_templates()

@router.get("/case/{case_id}/pdf-data", summary="Lấy luồng dữ liệu PDF vụ việc để PDF.js render")
async def get_case_pdf_data(
    case_id: str,
    template_file: str = Query("danh_sach_doi_tuong.docx", description="Tên file mẫu docx"),
    force: bool = Query(False, description="Bắt buộc render lại và bỏ qua cache"),
):
    """
    Kết xuất file Word vụ việc và chuyển sang PDF (có Cache), trả về stream nhị phân application/octet-stream
    kèm Cache-Control để phản hồi ngay lập tức trong 0ms.
    """
    case = case_storage.get_case(case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Không tìm thấy thông tin vụ việc")

    try:
        pdf_path = case_docx_service.generate_pdf(
            template_filename=template_file,
            case_data=case,
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
        raise HTTPException(status_code=500, detail=f"Lỗi tạo tài liệu PDF vụ việc: {str(e)}")

@router.get("/case/{case_id}/preview-viewer", summary="Trang HTML xem trước tài liệu PDF vụ việc qua PDF.js Canvas")
async def get_case_preview_viewer(
    request: Request,
    case_id: str,
    template_file: str = Query("danh_sach_doi_tuong.docx", description="Tên file mẫu docx"),
    force: bool = Query(False, description="Bắt buộc render lại và bỏ qua cache"),
    t: Optional[str] = Query(None, description="Timestamp tránh cache")
):
    """
    Trả về giao diện Web sử dụng Mozilla PDF.js vẽ từng trang A4 lên HTML5 Canvas cho vụ việc.
    """
    encoded_tpl_name = quote(template_file)
    cur_time = t or str(int(time.time() * 1000))
    force_param = f"&force=true&t={cur_time}" if force else f"&t={cur_time}"
    pdf_data_url = f"/api/v1/generate/case/{case_id}/pdf-data?template_file={encoded_tpl_name}{force_param}"

    return templates.TemplateResponse(
        request=request,
        name="preview_viewer.html",
        context={
            "pdf_data_url": pdf_data_url,
            "force": force
        }
    )

@router.post("/case/{case_id}/download", summary="Tải file Word vụ việc theo template")
async def download_case_docx(
    case_id: str,
    template_file: str = Query("danh_sach_doi_tuong.docx", description="Tên file mẫu docx")
):
    case = case_storage.get_case(case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Không tìm thấy thông tin vụ việc")

    try:
        buffer = case_docx_service.generate_docx_bytes(
            template_filename=template_file,
            case_data=case
        )
        templates_list = case_docx_service.get_templates()
        matched = [tpl["display_name"] for tpl in templates_list if tpl.get("file_name") == template_file]
        display_tpl_name = matched[0] if matched else template_file.replace(".docx", "")
        safe_case_name = case.ten_tom_tat.strip() if case.ten_tom_tat.strip() else "VuViec"
        download_filename = f"{display_tpl_name} - {safe_case_name}.docx"

        encoded_filename = quote(download_filename)
        safe_ascii_filename = template_file.replace(".docx", "")
        headers = {
            "Content-Disposition": f"attachment; filename=\"{safe_ascii_filename}\"; filename*=UTF-8''{encoded_filename}"
        }

        return StreamingResponse(
            buffer,
            media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            headers=headers
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi tạo tài liệu Word vụ việc: {str(e)}")


# ==============================================================================
# 3. CÁC API XUẤT VĂN BẢN TÙY BIẾN (CUSTOM DOCUMENT LEVEL)
# ==============================================================================

@router.get("/templates/custom/case", summary="Lấy danh sách các mẫu văn bản tùy biến cấp vụ án")
async def get_custom_case_templates():
    """Trả về danh sách các mẫu văn bản tùy biến từ templates/custom/case/metadata.json"""
    return custom_docx_service.get_templates(level="case")

@router.get("/templates/custom/person", summary="Lấy danh sách các mẫu văn bản tùy biến cấp cá nhân")
async def get_custom_person_templates():
    """Trả về danh sách các mẫu văn bản tùy biến từ templates/custom/person/metadata.json"""
    return custom_docx_service.get_templates(level="person")

@router.get("/templates/custom", summary="Lấy danh sách các mẫu văn bản tùy biến")
async def get_custom_templates(level: str = Query("case", description="case hoặc person")):
    """Trả về danh sách các mẫu văn bản tùy biến theo cấp độ tương ứng"""
    return custom_docx_service.get_templates(level=level)

@router.get("/custom/{case_id}/{doc_id}/pdf-data", summary="Lấy luồng dữ liệu PDF biên bản tùy biến để PDF.js render")
async def get_custom_pdf_data(
    case_id: str,
    doc_id: str,
    person_id: Optional[str] = Query(None, description="ID của cá nhân nếu là biên bản cấp cá nhân"),
    force: bool = Query(False, description="Bắt buộc render lại và bỏ qua cache"),
):
    """
    Kết xuất file Word tùy biến và chuyển sang PDF (có Cache), trả về stream nhị phân application/octet-stream.
    """
    case = case_storage.get_case(case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Không tìm thấy vụ việc")

    custom_doc = custom_doc_storage.get_custom_doc(case_id, doc_id, person_id=person_id)
    if not custom_doc:
        raise HTTPException(status_code=404, detail="Không tìm thấy biên bản tùy biến trong dữ liệu")

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
        raise HTTPException(status_code=500, detail=f"Lỗi tạo tài liệu PDF tùy biến: {str(e)}")

@router.get("/custom/{case_id}/{doc_id}/preview-viewer", summary="Trang HTML xem trước tài liệu PDF tùy biến qua PDF.js Canvas")
async def get_custom_preview_viewer(
    request: Request,
    case_id: str,
    doc_id: str,
    person_id: Optional[str] = Query(None, description="ID của cá nhân nếu có"),
    force: bool = Query(False, description="Bắt buộc render lại và bỏ qua cache"),
    t: Optional[str] = Query(None, description="Timestamp tránh cache")
):
    """
    Trả về giao diện Web sử dụng Mozilla PDF.js vẽ từng trang A4 lên HTML5 Canvas cho biên bản tùy biến.
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

@router.post("/custom/{case_id}/{doc_id}/download", summary="Tải file Word biên bản tùy biến")
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
        raise HTTPException(status_code=404, detail="Không tìm thấy biên bản tùy biến trong vụ việc")

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
        safe_title = custom_doc.title.strip() if custom_doc.title.strip() else "BienBan"
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
        raise HTTPException(status_code=500, detail=f"Lỗi tạo tài liệu Word tùy biến: {str(e)}")