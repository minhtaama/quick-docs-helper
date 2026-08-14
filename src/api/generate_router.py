from typing import Optional
from fastapi import APIRouter, Form, File, UploadFile, HTTPException
from fastapi.responses import FileResponse
from src.schemas.document_schema import PersonData
from src.services.docx_service import DocxService
from src.services.storage_service import StorageService

router = APIRouter(prefix="/api/v1/generate", tags=["Document Generation"])
docx_service = DocxService()
storage_service = StorageService()

@router.post("/ly-lich-ca-nhan/{case_id}/{person_id}", summary="Tạo file Word Lý lịch từ dữ liệu đã lưu trong vụ việc")
async def generate_ly_lich(case_id: str, person_id: str):
    """
    Đọc dữ liệu của cá nhân đã lưu trong vụ việc (JSON + Ảnh)
    và tự động kết xuất ra file Word mẫu lý-lịch-cá-nhân để tải về.
    """
    person = storage_service.get_person(case_id, person_id)
    if not person:
        raise HTTPException(status_code=404, detail="Không tìm thấy thông tin cá nhân trong vụ việc")

    try:
        output_path = docx_service.generate_docx_from_person(
            template_filename="ly-lich-ca-nhan.docx",
            person_data=person
        )

        return FileResponse(
            output_path,
            media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            filename=f"LyLich_{person.ho_ten or 'CaNhan'}.docx"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi tạo tài liệu Word: {str(e)}")