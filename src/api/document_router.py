from fastapi import APIRouter, Form, File, UploadFile, HTTPException
from fastapi.responses import FileResponse
from src.schemas.document_schema import PersonData
from src.services.docx_service import DocxService

router = APIRouter(prefix="/api/documents", tags=["Documents"])
docx_service = DocxService()

@router.post("/generate-ly-lich")
async def generate_ly_lich(
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
    image: UploadFile = File(None)
):
    """Endpoint tiếp nhận thông tin form và tạo file Word Lý Lịch"""
    try:
        data = PersonData(
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
            doan_the=doan_the
        )
        
        image_bytes = None
        if image and image.filename:
            image_bytes = await image.read()

        output_path = docx_service.generate_docx_from_person(data, image_bytes=image_bytes)

        return FileResponse(
            output_path,
            media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            filename=f"LyLich_{data.ho_ten or 'CaNhan'}.docx"
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi tạo tài liệu: {str(e)}")
