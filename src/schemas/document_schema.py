import uuid
from typing import Optional, Any
from datetime import datetime
from pydantic import BaseModel, Field, field_validator, model_validator

class RecordData(BaseModel):
    """Schema đại diện cho một tiền án/tiền sự"""
    thoi_gian: str = ""
    noi_dung: str = ""

class FamilyData(BaseModel):
    """Schema đại diện cho một người thân/thành viên trong gia đình"""
    quan_he: str = ""
    gioi_tinh: str = ""
    ho_ten: str = ""
    nam_sinh: str = ""
    nghe_nghiep: str = ""
    noi_o: str = ""

class CustomDocumentData(BaseModel):
    """Schema đại diện cho một văn bản tùy biến có chứa các trường động"""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    template_file: str = ""
    title: str = ""
    custom_fields: dict[str, Any] = Field(default_factory=dict)
    created_at: str = Field(default_factory=lambda: datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    updated_at: str = Field(default_factory=lambda: datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

class PersonData(BaseModel):
    """
    Schema chứa thông tin con người trong vụ án/vụ việc
    """
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    isdt: bool = True
    ho_ten: str = ""
    gioi_tinh: str = ""
    ngay_sinh: str = ""
    thang_sinh: str = ""
    nam_sinh: str = ""
    noi_sinh: str = ""
    que_quan: str = ""
    quoc_tich: str = ""
    dan_toc: str = ""
    ton_giao: str = ""
    cccd: str = ""
    ngay_cccd: str = ""
    thang_cccd: str = ""
    nam_cccd: str = ""
    noi_cap_cccd: str = ""
    hoc_van: str = ""
    nghe_nghiep: str = ""
    noi_lam_viec: str = ""
    noi_thuong_tru: str = ""
    noi_tam_tru: str = ""
    noi_o_hien_tai: str = ""
    chuc_vu: str = ""
    doan_the: str = ""
    tien_an_tien_su: list[RecordData] = []
    quan_he_gia_dinh: list[FamilyData] = []
    custom_documents: list[CustomDocumentData] = []
    image_path: Optional[str] = None

    @field_validator("tien_an_tien_su", mode="before")
    @classmethod
    def parse_tien_an_tien_su(cls, v):
        if isinstance(v, str):
            if not v or v.strip() == "Chưa có tiền án, tiền sự":
                return []
            try:
                import json
                data = json.loads(v)
                if isinstance(data, list):
                    return data
            except Exception:
                pass
            return []
        return v or []

class CaseCreate(BaseModel):
    """Schema khi tạo mới hoặc cập nhật một vụ án/vụ việc"""
    id: Optional[str] = None
    ten_tom_tat: str = ""
    ten_day_du: str = ""

    @model_validator(mode="before")
    @classmethod
    def handle_legacy_keys(cls, data: Any) -> Any:
        if isinstance(data, dict):
            if "ten_vu" in data and not data.get("ten_tom_tat"):
                data["ten_tom_tat"] = data["ten_vu"]
            if "mo_ta" in data and not data.get("ten_day_du"):
                data["ten_day_du"] = data["mo_ta"]
        return data

class CaseData(BaseModel):
    """
    Schema chứa thông tin tổng thể của một vụ án/vụ việc
    """
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    ten_tom_tat: str = ""
    ten_day_du: str = ""
    created_at: str = Field(default_factory=lambda: datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    updated_at: str = Field(default_factory=lambda: datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    con_nguoi_list: list[PersonData] = []
    custom_documents: list[CustomDocumentData] = []

    @model_validator(mode="before")
    @classmethod
    def handle_legacy_keys(cls, data: Any) -> Any:
        if isinstance(data, dict):
            if "ten_vu" in data and not data.get("ten_tom_tat"):
                data["ten_tom_tat"] = data["ten_vu"]
            if "mo_ta" in data and not data.get("ten_day_du"):
                data["ten_day_du"] = data["mo_ta"]
        return data
