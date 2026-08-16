import uuid
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, Field

class FamilyData(BaseModel):
    """Schema đại diện cho một người thân/thành viên trong gia đình"""
    quan_he: str = ""
    ho_ten: str = ""
    nam_sinh: str = ""
    nghe_nghiep: str = ""
    noi_o: str = ""

class PersonData(BaseModel):
    """
    Schema chứa thông tin con người trong vụ án/vụ việc
    """
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
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
    tien_an_tien_su: str = "Chưa có tiền án, tiền sự"
    quan_he_gia_dinh: List[FamilyData] = []
    image_path: Optional[str] = None

class CaseCreate(BaseModel):
    """Schema khi tạo mới hoặc cập nhật một vụ án/vụ việc"""
    id: Optional[str] = None
    ten_vu: str
    mo_ta: str = ""

CaseSave = CaseCreate

class CaseData(BaseModel):
    """
    Schema chứa thông tin tổng thể của một vụ án/vụ việc
    """
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    ten_vu: str = ""
    mo_ta: str = ""
    created_at: str = Field(default_factory=lambda: datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    updated_at: str = Field(default_factory=lambda: datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    con_nguoi_list: list[PersonData] = []
