import io
import os
from typing import Optional
from docxtpl import DocxTemplate, InlineImage
from docx.shared import Mm
from src.schemas.document_schema import LyLichData

class DocxService:
    """Service chịu trách nhiệm xử lý template Word và xuất file kết quả"""
    
    def __init__(self, template_dir: str = "templates"):
        self.template_dir = template_dir

    def generate_ly_lich_doc(self, data: LyLichData, image_bytes: Optional[bytes] = None) -> str:
        template_path = os.path.join(self.template_dir, "ly-lich-ca-nhan.docx")
        if not os.path.exists(template_path):
            raise FileNotFoundError(f"Không tìm thấy file mẫu tại {template_path}")

        tpl = DocxTemplate(template_path)
        
        img_obj = ""
        if image_bytes:
            img_io = io.BytesIO(image_bytes)
            img_obj = InlineImage(tpl, image_descriptor=img_io, width=Mm(30))

        context = data.model_dump()
        context["image"] = img_obj

        tpl.render(context)
        output_dir = "temp_outputs"
        os.makedirs(output_dir, exist_ok=True)
        output_filename = f"LyLich_{data.ho_ten or 'CaNhan'}.docx"
        output_path = os.path.join(output_dir, output_filename)
        tpl.save(output_path)
        
        return output_path
