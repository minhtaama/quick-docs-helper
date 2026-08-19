from fastapi import APIRouter, HTTPException
from src.schemas.document_schema import CustomDocumentData
from src.services.storage_service import CustomDocStorageService
from src.services.docx_service import CustomDocxService

router = APIRouter(prefix="/api/v1/cases/{case_id}/custom-docs", tags=["Custom Documents"])
custom_storage = CustomDocStorageService()
custom_docx_service = CustomDocxService()


@router.get("", summary="Lấy danh sách tất cả các biên bản tùy biến trong vụ án")
@router.get("/", include_in_schema=False)
async def list_custom_docs(case_id: str):
    """
    Trả về danh sách toàn bộ các biên bản tùy biến thuộc về một vụ việc cụ thể.
    """
    case = custom_storage.get_case(case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Không tìm thấy thông tin vụ việc")
    return custom_storage.list_custom_docs(case_id)


@router.get("/{doc_id}", summary="Lấy chi tiết một biên bản tùy biến")
async def get_custom_doc(case_id: str, doc_id: str):
    """
    Lấy thông tin chi tiết của một biên bản tùy biến theo ID.
    """
    doc = custom_storage.get_custom_doc(case_id, doc_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Không tìm thấy biên bản tùy biến")
    return doc


@router.post("", summary="Thêm hoặc cập nhật một biên bản tùy biến")
@router.post("/", include_in_schema=False)
async def add_or_update_custom_doc(case_id: str, payload: CustomDocumentData):
    """
    Tạo mới một biên bản tùy biến hoặc cập nhật dữ liệu của biên bản đã lưu trong vụ việc.
    """
    case = custom_storage.get_case(case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Không tìm thấy thông tin vụ việc")

    saved_doc = custom_storage.add_or_update_custom_doc(case_id, payload)
    if not saved_doc:
        raise HTTPException(status_code=500, detail="Không thể lưu biên bản tùy biến")

    # Xóa cache PDF cũ khi biên bản được cập nhật
    custom_docx_service.clear_cache(saved_doc.id)
    return saved_doc


@router.delete("/{doc_id}", summary="Xóa một biên bản tùy biến")
async def delete_custom_doc(case_id: str, doc_id: str):
    """
    Xóa một biên bản tùy biến khỏi vụ việc đã chọn.
    """
    success = custom_storage.delete_custom_doc(case_id, doc_id)
    if not success:
        raise HTTPException(status_code=404, detail="Không tìm thấy biên bản tùy biến để xóa")

    # Xóa cache PDF liên quan
    custom_docx_service.clear_cache(doc_id)
    return {"message": "Đã xóa biên bản tùy biến thành công", "doc_id": doc_id}
