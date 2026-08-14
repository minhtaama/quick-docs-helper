import io
import os
from typing import Optional
from docxtpl import DocxTemplate, InlineImage
from docx.shared import Mm
from src.schemas.document_schema import PersonData, CaseData
from src.config import BASE_DIR, TEMPLATES_DIR, TEMP_OUTPUTS_DIR

class DocxService:
    """
    Service chịu trách nhiệm xử lý template Word và xuất file kết quả.
    File kết quả sẽ được lưu trữ trên máy chủ.
    """
    
    def __init__(self, template_dir: Optional[str] = None):
        if template_dir is None:
            self.template_dir = TEMPLATES_DIR
        elif os.path.isabs(template_dir):
            self.template_dir = template_dir
        else:
            self.template_dir = os.path.join(BASE_DIR, template_dir)

        self.output_dir = TEMP_OUTPUTS_DIR

    def generate_docx_from_person(self, template_filename: str, person_data: PersonData, person_img_bytes: Optional[bytes] = None) -> str:
        template_path = os.path.join(self.template_dir, template_filename)

        if not os.path.exists(template_path):
            raise FileNotFoundError(f"Không tìm thấy file docx: {template_path}")

        template_doc = DocxTemplate(template_path)
        
        img_obj = ""
        if person_img_bytes:
            img_io = io.BytesIO(person_img_bytes)
            img_obj = InlineImage(template_doc, image_descriptor=img_io, width=Mm(30))

        context = person_data.model_dump()
        context["image"] = img_obj

        template_doc.render(context)

        os.makedirs(self.output_dir, exist_ok=True)
        output_filename = f"{template_filename.split('.')[0]} - {person_data.ho_ten}.docx"
        output_path = os.path.join(self.output_dir, output_filename)
        template_doc.save(output_path)
    
        return output_path
