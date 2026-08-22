import io
import urllib.parse
from typing import Any
from fastapi import APIRouter, HTTPException, Body
from fastapi.responses import StreamingResponse
from src.services.bundle_service import BundleService
from src.services.storage_service import CaseStorageService

router = APIRouter(prefix="/api/v1", tags=["Document Bundles"])
bundle_service = BundleService()
case_storage = CaseStorageService()


@router.get("/bundles")
def list_bundles() -> list[dict[str, Any]]:
    """Lấy danh sách tất cả các gói Bundle mẫu"""
    return bundle_service.get_bundles()


@router.get("/cases/{case_id}/bundles/{bundle_id}/layout")
def get_case_bundle_layout(case_id: str, bundle_id: str) -> dict[str, Any]:
    """Lấy layout chi tiết của toàn bộ các tờ A4 trong Bundle cho một vụ án cụ thể"""
    layout = bundle_service.get_bundle_layout(case_id, bundle_id)
    if not layout:
        raise HTTPException(status_code=404, detail="Không tìm thấy Bundle hoặc Vụ án")
    return layout


@router.get("/cases/{case_id}/bundles/history")
def get_case_bundles_history(case_id: str) -> list[dict[str, Any]]:
    """Lấy lịch sử các gói Bundle đã tạo của một vụ án"""
    case = case_storage.get_case(case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Không tìm thấy Vụ án")
    return getattr(case, "bundles", [])


@router.post("/cases/{case_id}/bundles/{bundle_id}/render")
def render_case_bundle(
    case_id: str,
    bundle_id: str,
    payload: dict[str, Any] = Body(default_factory=dict)
):
    """
    Lưu dữ liệu Bundle 2 chiều (Case + Person) và xuất trọn bộ file nén ZIP.
    Payload:
    - documents_data: Map từ doc_key -> custom_fields
    - bundle_instance_id: (tuỳ chọn) Mã phiên bản bundle
    """
    documents_data = payload.get("documents_data", {})
    bundle_instance_id = payload.get("bundle_instance_id")

    try:
        zip_bytes, zip_filename = bundle_service.save_and_render_bundle(
            case_id=case_id,
            bundle_id=bundle_id,
            documents_data=documents_data,
            bundle_instance_id=bundle_instance_id
        )

        encoded_filename = urllib.parse.quote(zip_filename)
        return StreamingResponse(
            io.BytesIO(zip_bytes),
            media_type="application/zip",
            headers={
                "Content-Disposition": f"attachment; filename*=UTF-8''{encoded_filename}",
                "Access-Control-Expose-Headers": "Content-Disposition"
            }
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
