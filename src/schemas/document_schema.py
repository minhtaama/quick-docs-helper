from pydantic import BaseModel

class PersonData(BaseModel):
    """
    Schema chứa thông tin con người trong vụ án/vụ việc
    """
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

class CaseData(BaseModel):
    ten_vu_an: str = ""
    con_nguoi: list[PersonData] = []
    
