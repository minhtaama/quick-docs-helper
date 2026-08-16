from typing import Optional
import os
import urllib.parse
from fastapi import APIRouter, Form, File, UploadFile, HTTPException, Query
from fastapi.responses import FileResponse, HTMLResponse, Response
from src.schemas.document_schema import PersonData
from src.services.docx_service import DocxService
from src.services.storage_service import StorageService

router = APIRouter(prefix="/api/v1/generate", tags=["Document Generation"])
docx_service = DocxService()
storage_service = StorageService()

@router.get("/templates/person", summary="Lấy danh sách các mẫu văn bản dành cho cá nhân")
async def get_person_templates():
    """
    Trả về danh sách các mẫu văn bản từ thư mục templates/person/metadata.json
    """
    return docx_service.get_person_templates()

@router.get("/person/{case_id}/{person_id}/pdf-data", summary="Lấy luồng dữ liệu PDF để PDF.js render")
async def get_person_pdf_data(
    case_id: str,
    person_id: str,
    template_file: str = Query("ly-lich-ca-nhan.docx", description="Tên file mẫu docx")
):
    """
    Kết xuất file Word và chuyển sang PDF (có tích hợp Cache), trả về stream nhị phân application/octet-stream
    kèm Cache-Control để phản hồi ngay lập tức trong 0ms khi chuyển đổi giữa các mẫu.
    """
    person = storage_service.get_person(case_id, person_id)
    if not person:
        raise HTTPException(status_code=404, detail="Không tìm thấy thông tin cá nhân trong vụ việc")

    try:
        pdf_path = docx_service.generate_pdf_from_person(
            template_filename=template_file,
            person_data=person
        )
        return FileResponse(
            pdf_path,
            media_type="application/octet-stream",
            headers={
                "Content-Disposition": "inline; filename=preview.bin",
                "Cache-Control": "public, max-age=86400"
            }
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi tạo tài liệu PDF: {str(e)}")

@router.get("/person/{case_id}/{person_id}/docx-raw", summary="Lấy tệp DOCX đã render dạng raw binary")
async def get_person_docx_raw(
    case_id: str,
    person_id: str,
    template_file: str = Query("ly-lich-ca-nhan.docx", description="Tên file mẫu docx")
):
    person = storage_service.get_person(case_id, person_id)
    if not person:
        raise HTTPException(status_code=404, detail="Không tìm thấy thông tin cá nhân trong vụ việc")

    try:
        output_path = docx_service.generate_docx_from_person(
            template_filename=template_file,
            person_data=person
        )
        return FileResponse(
            output_path,
            media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            filename=os.path.basename(output_path)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi tạo tài liệu Word: {str(e)}")

@router.get("/person/{case_id}/{person_id}/preview-viewer", summary="Trang HTML xem trước tài liệu PDF qua PDF.js Canvas (Chống IDM bắt link & Có Cache)")
async def get_person_docx_preview_viewer(
    case_id: str,
    person_id: str,
    template_file: str = Query("ly-lich-ca-nhan.docx", description="Tên file mẫu docx")
):
    """
    Trả về giao diện Web sử dụng Mozilla PDF.js vẽ từng trang A4 lên HTML5 Canvas,
    đảm bảo không bị IDM can thiệp, chuẩn 100% định dạng Word và tốc độ tức thì nhờ Cache.
    """
    encoded_tpl = urllib.parse.quote(template_file)
    pdf_data_url = f"/api/v1/generate/person/{case_id}/{person_id}/pdf-data?template_file={encoded_tpl}"

    html_content = f"""<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Xem trước văn bản</title>
    <!-- Mozilla PDF.js CDN -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        html, body {{
            width: 100%;
            height: 100%;
            overflow-x: hidden;
            overflow-y: auto;
            background-color: #525659;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 20px 10px;
        }}
        #loading {{
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            color: #ffffff;
            font-size: 14px;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 12px;
            z-index: 10;
            background: rgba(0,0,0,0.65);
            padding: 20px 28px;
            border-radius: 12px;
            box-shadow: 0 4px 16px rgba(0,0,0,0.3);
            backdrop-filter: blur(4px);
        }}
        .spinner {{
            width: 32px;
            height: 32px;
            border: 3.5px solid rgba(255, 255, 255, 0.25);
            border-top: 3.5px solid #ffffff;
            border-radius: 50%;
            animation: spin 0.7s linear infinite;
        }}
        @keyframes spin {{
            0% {{ transform: rotate(0deg); }}
            100% {{ transform: rotate(360deg); }}
        }}
        #pdf-container {{
            display: flex;
            flex-direction: column;
            align-items: center;
            width: 100%;
            max-width: 900px;
        }}
        .pdf-page {{
            background: #ffffff;
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.35);
            border-radius: 3px;
            margin-bottom: 24px;
            overflow: hidden;
            display: flex;
            justify-content: center;
            align-items: center;
        }}
        .pdf-page canvas {{
            display: block;
        }}
        #error-box {{
            display: none;
            background: #fde8e8;
            color: #c53030;
            padding: 16px 24px;
            border-radius: 8px;
            border: 1px solid #feb2b2;
            max-width: 500px;
            margin-top: 40px;
            text-align: center;
            font-size: 14px;
            line-height: 1.5;
        }}
    </style>
</head>
<body>
    <div id="loading">
        <div class="spinner"></div>
        <span>Đang nạp bản xem trước chuẩn 100%...</span>
    </div>
    <div id="error-box"></div>
    <div id="pdf-container"></div>

    <script>
        const pdfDataUrl = "{pdf_data_url}";
        const container = document.getElementById("pdf-container");
        const loading = document.getElementById("loading");
        const errorBox = document.getElementById("error-box");

        pdfjsLib.GlobalWorkerOptions.workerSrc = "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js";

        // Khởi tạo bộ nhớ đệm phía Client (RAM Cache)
        window.__clientPdfCache = window.__clientPdfCache || {{}};

        async function renderPdf() {{
            try {{
                let arrayBuffer;
                if (window.__clientPdfCache[pdfDataUrl]) {{
                    arrayBuffer = window.__clientPdfCache[pdfDataUrl];
                }} else {{
                    const response = await fetch(pdfDataUrl);
                    if (!response.ok) {{
                        throw new Error("Không thể nạp tài liệu (Mã lỗi: " + response.status + ")");
                    }}
                    arrayBuffer = await response.arrayBuffer();
                    window.__clientPdfCache[pdfDataUrl] = arrayBuffer;
                }}

                const loadingTask = pdfjsLib.getDocument({{ data: arrayBuffer }});
                const pdf = await loadingTask.promise;

                loading.style.display = "none";
                container.innerHTML = "";

                // Render tuần tự từng trang A4
                for (let pageNum = 1; pageNum <= pdf.numPages; pageNum++) {{
                    const page = await pdf.getPage(pageNum);
                    
                    const unscaledViewport = page.getViewport({{ scale: 1.0 }});
                    const targetWidth = Math.min(window.innerWidth - 40, 820);
                    const scale = targetWidth / unscaledViewport.width;
                    const viewport = page.getViewport({{ scale: Math.max(scale, 1.25) }});
                    
                    const pageDiv = document.createElement("div");
                    pageDiv.className = "pdf-page";
                    pageDiv.style.width = viewport.width + "px";
                    pageDiv.style.height = viewport.height + "px";

                    const canvas = document.createElement("canvas");
                    const context = canvas.getContext("2d");
                    
                    const dpr = window.devicePixelRatio || 1;
                    canvas.width = viewport.width * dpr;
                    canvas.height = viewport.height * dpr;
                    canvas.style.width = viewport.width + "px";
                    canvas.style.height = viewport.height + "px";

                    context.scale(dpr, dpr);

                    pageDiv.appendChild(canvas);
                    container.appendChild(pageDiv);

                    await page.render({{
                        canvasContext: context,
                        viewport: viewport
                    }}).promise;
                }}
            }} catch (err) {{
                loading.style.display = "none";
                errorBox.style.display = "block";
                errorBox.innerHTML = "<strong>Lỗi xem trước:</strong> " + err.message;
                console.error("PDF.js Render Error:", err);
            }}
        }}

        window.addEventListener("DOMContentLoaded", renderPdf);
    </script>
</body>
</html>
"""
    return HTMLResponse(content=html_content)

@router.post("/person/{case_id}/{person_id}/download", summary="Tải file Word theo template")
async def download_person_docx(
    case_id: str,
    person_id: str,
    template_file: str = Query("ly-lich-ca-nhan.docx", description="Tên file mẫu docx")
):
    person = storage_service.get_person(case_id, person_id)
    if not person:
        raise HTTPException(status_code=404, detail="Không tìm thấy thông tin cá nhân trong vụ việc")

    try:
        output_path = docx_service.generate_docx_from_person(
            template_filename=template_file,
            person_data=person
        )
        safe_person_name = person.ho_ten.strip() if person.ho_ten.strip() else "CaNhan"
        clean_tpl_name = template_file.replace(".docx", "")
        download_filename = f"{clean_tpl_name}_{safe_person_name}.docx"

        return FileResponse(
            output_path,
            media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            filename=download_filename
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi tạo tài liệu Word: {str(e)}")