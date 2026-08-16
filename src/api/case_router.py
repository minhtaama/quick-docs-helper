from fastapi.responses import Response
import os
import json
from typing import List, Optional
from fastapi import APIRouter, Form, File, UploadFile, HTTPException
from src.schemas.document_schema import CaseData, CaseCreate, PersonData, FamilyData
from src.services.storage_service import StorageService
from src.services.docx_service import DocxService

router = APIRouter(prefix="/api/v1/cases", tags=["Cases & Persons"])
storage_service = StorageService()
docx_service = DocxService()

@router.get("", summary="Lấy danh sách tất cả vụ việc")
@router.get("/", include_in_schema=False)
async def list_cases():
    """Trả về danh sách tóm tắt tất cả các vụ án/vụ việc đã lưu trên hệ thống"""
    return storage_service.list_cases()

@router.post("", summary="Thêm hoặc cập nhật một vụ việc")
@router.post("/", include_in_schema=False)
async def add_or_update_case(payload: CaseCreate):
    """Tạo mới một vụ việc hoặc cập nhật tên/mô tả của vụ việc đã có"""
    if payload.id:
        existing_case = storage_service.get_case(payload.id)
        if not existing_case:
            raise HTTPException(status_code=404, detail="Không tìm thấy vụ việc để cập nhật")
        existing_case.ten_vu = payload.ten_vu
        existing_case.mo_ta = payload.mo_ta
        saved = storage_service.save_case(existing_case)
        return saved

    new_case = CaseData(
        ten_vu=payload.ten_vu,
        mo_ta=payload.mo_ta
    )
    saved = storage_service.save_case(new_case)
    return saved

@router.get("/{case_id}", summary="Lấy chi tiết vụ việc")
async def get_case(case_id: str):
    """Lấy toàn bộ thông tin vụ việc và danh sách con người bên trong"""
    case = storage_service.get_case(case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Không tìm thấy vụ việc")
    return case

@router.delete("/{case_id}", summary="Xóa vụ việc")
async def delete_case(case_id: str):
    """Xóa hoàn toàn vụ việc và toàn bộ tệp tin dữ liệu/ảnh đính kèm"""
    success = storage_service.delete_case(case_id)
    if not success:
        raise HTTPException(status_code=404, detail="Không tìm thấy vụ việc để xóa")
    return {"message": "Đã xóa vụ việc thành công", "case_id": case_id}

@router.post("/{case_id}/persons", summary="Thêm hoặc cập nhật một cá nhân trong vụ việc")
async def add_or_update_person(
    case_id: str,
    person_id: Optional[str] = Form(None),
    ho_ten: str = Form(""),
    gioi_tinh: str = Form(""),
    ngay_sinh: str = Form(""),
    thang_sinh: str = Form(""),
    nam_sinh: str = Form(""),
    noi_sinh: str = Form(""),
    que_quan: str = Form(""),
    quoc_tich: str = Form(""),
    dan_toc: str = Form(""),
    ton_giao: str = Form(""),
    cccd: str = Form(""),
    ngay_cccd: str = Form(""),
    thang_cccd: str = Form(""),
    nam_cccd: str = Form(""),
    noi_cap_cccd: str = Form(""),
    hoc_van: str = Form(""),
    nghe_nghiep: str = Form(""),
    noi_lam_viec: str = Form(""),
    noi_thuong_tru: str = Form(""),
    noi_tam_tru: str = Form(""),
    noi_o_hien_tai: str = Form(""),
    chuc_vu: str = Form(""),
    doan_the: str = Form(""),
    tien_an_tien_su: str = Form("Chưa có tiền án, tiền sự"),
    quan_he_gia_dinh: str = Form("[]"),
    image: Optional[UploadFile] = File(None)
):
    """Thêm một con người mới hoặc cập nhật thông tin con người kèm ảnh đại diện vào vụ việc"""
    case = storage_service.get_case(case_id)
    if not case:
        raise HTTPException(status_code=404, detail="Không tìm thấy vụ việc")

    parsed_gia_dinh = []
    if quan_he_gia_dinh:
        try:
            raw_list = json.loads(quan_he_gia_dinh)
            if isinstance(raw_list, list):
                for item in raw_list:
                    if isinstance(item, dict):
                        parsed_gia_dinh.append(FamilyData(**item))
        except Exception as e:
            print(f"Error parsing quan_he_gia_dinh: {e}")

    # Khởi tạo đối tượng PersonData
    person_data = PersonData(
        ho_ten=ho_ten,
        gioi_tinh=gioi_tinh,
        ngay_sinh=ngay_sinh,
        thang_sinh=thang_sinh,
        nam_sinh=nam_sinh,
        noi_sinh=noi_sinh,
        que_quan=que_quan,
        quoc_tich=quoc_tich,
        dan_toc=dan_toc,
        ton_giao=ton_giao,
        cccd=cccd,
        ngay_cccd=ngay_cccd,
        thang_cccd=thang_cccd,
        nam_cccd=nam_cccd,
        noi_cap_cccd=noi_cap_cccd,
        hoc_van=hoc_van,
        nghe_nghiep=nghe_nghiep,
        noi_lam_viec=noi_lam_viec,
        noi_thuong_tru=noi_thuong_tru,
        noi_tam_tru=noi_tam_tru,
        noi_o_hien_tai=noi_o_hien_tai,
        chuc_vu=chuc_vu,
        doan_the=doan_the,
        tien_an_tien_su=tien_an_tien_su,
        quan_he_gia_dinh=parsed_gia_dinh
    )

    if person_id:
        person_data.id = person_id

    image_bytes = None
    image_ext = "jpg"
    if image and image.filename:
        image_bytes = await image.read()
        _, ext = os.path.splitext(image.filename)
        if ext:
            image_ext = ext

    saved_person = storage_service.add_or_update_person(
        case_id=case_id,
        person_data=person_data,
        image_bytes=image_bytes,
        image_ext=image_ext
    )

    # Dọn dẹp cache PDF cũ để khi xuất lại sẽ tự động làm mới
    if saved_person and saved_person.id:
        docx_service.clear_person_cache(saved_person.id)

    return saved_person

@router.delete("/{case_id}/persons/{person_id}", summary="Xóa một cá nhân khỏi vụ việc")
async def delete_person(case_id: str, person_id: str):
    """Xóa một con người khỏi vụ việc đã chọn"""
    success = storage_service.delete_person(case_id, person_id)
    if not success:
        raise HTTPException(status_code=404, detail="Không tìm thấy cá nhân hoặc vụ việc")
    docx_service.clear_person_cache(person_id)
    return {"message": "Đã xóa cá nhân khỏi vụ việc", "person_id": person_id}

@router.get("/{case_id}/persons/{person_id}/image", summary="Lấy ảnh đại diện của cá nhân")
async def get_person_image(case_id: str, person_id: str):
    image_bytes = storage_service.get_person_image_bytes(case_id, person_id)
    if not image_bytes:
        raise HTTPException(status_code=404, detail="Không tìm thấy ảnh đại diện")
    return Response(content=image_bytes, media_type="image/png")
