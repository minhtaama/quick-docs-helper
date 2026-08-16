import io
import json
import os
import sys
import hashlib
from typing import Optional, List, Dict, Any
from docxtpl import DocxTemplate, InlineImage
from docx.shared import Mm
from src.schemas.document_schema import PersonData, CaseData
from src.config import BASE_DIR, TEMPLATES_DIR, TEMP_OUTPUTS_DIR

class DocxService:
    """
    Service chịu trách nhiệm xử lý template Word và xuất file kết quả.
    File kết quả sẽ được lưu trữ trên máy chủ và tự động cache PDF.
    """
    
    def __init__(self, template_dir: Optional[str] = None):
        if template_dir is None:
            self.template_dir = TEMPLATES_DIR
        elif os.path.isabs(template_dir):
            self.template_dir = template_dir
        else:
            self.template_dir = os.path.join(BASE_DIR, template_dir)

        self.output_dir = TEMP_OUTPUTS_DIR
        self.cache_dir = os.path.join(self.output_dir, "cache_pdf")
        os.makedirs(self.cache_dir, exist_ok=True)

    def _resolve_template_path(self, template_filename: str) -> str:
        # Kiểm tra trong thư mục templates/person trước
        template_path = os.path.join(self.template_dir, "person", template_filename)
        if not os.path.exists(template_path):
            # Fallback về thư mục templates gốc
            template_path = os.path.join(self.template_dir, template_filename)
        return template_path

    def _get_cache_hash(self, template_path: str, person_data: PersonData) -> str:
        data_dict = person_data.model_dump()
        data_str = json.dumps(data_dict, sort_keys=True)
        tpl_mtime = str(os.path.getmtime(template_path)) if os.path.exists(template_path) else ""
        raw_key = f"{data_str}_{tpl_mtime}"
        return hashlib.md5(raw_key.encode('utf-8')).hexdigest()[:12]

    def get_person_templates(self) -> List[Dict[str, str]]:
        """
        Lấy danh sách các mẫu văn bản dành cho đối tượng từ metadata.json
        trong thư mục templates/person/
        """
        person_tpl_dir = os.path.join(self.template_dir, "person")
        metadata_path = os.path.join(person_tpl_dir, "metadata.json")

        if os.path.exists(metadata_path):
            try:
                with open(metadata_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    if isinstance(data, list):
                        return data
            except Exception as e:
                print(f"Error reading metadata.json: {e}")

        # Fallback: Quét các file .docx trong thư mục templates/person
        templates = []
        if os.path.exists(person_tpl_dir):
            for filename in os.listdir(person_tpl_dir):
                if filename.endswith(".docx") and not filename.startswith("~$"):
                    display_name = filename.replace(".docx", "").replace("-", " ").replace("_", " ").title()
                    templates.append({
                        "file_name": filename,
                        "display_name": display_name
                    })

        if not templates:
            templates = [{
                "file_name": "ly-lich-ca-nhan.docx",
                "display_name": "Bản khai lý lịch cá nhân"
            }]

        return templates

    def generate_docx_from_person(self, template_filename: str, person_data: PersonData) -> str:
        template_path = self._resolve_template_path(template_filename)

        if not os.path.exists(template_path):
            raise FileNotFoundError(f"Không tìm thấy file docx mẫu: {template_path}")

        template_doc = DocxTemplate(template_path)
        
        # Nếu có đường dẫn ảnh lưu trữ sẵn
        if person_data.image_path and os.path.exists(person_data.image_path):
            try:
                img_obj = InlineImage(template_doc, image_descriptor=person_data.image_path, width=Mm(30))
            except Exception as e:
                print(f"Error loading image into docx: {e}")
                img_obj = ""
        else:
            img_obj = ""

        context = person_data.model_dump()
        context["image"] = img_obj

        template_doc.render(context)

        os.makedirs(self.output_dir, exist_ok=True)
        safe_person_name = person_data.ho_ten.strip() if person_data.ho_ten.strip() else "CaNhan"
        clean_tpl_name = template_filename.replace(".docx", "")
        output_filename = f"{clean_tpl_name} - {safe_person_name}.docx"
        output_path = os.path.join(self.output_dir, output_filename)
        template_doc.save(output_path)
    
        return output_path

    def generate_pdf_from_person(self, template_filename: str, person_data: PersonData) -> str:
        """
        Render file Word (.docx) rồi chuyển đổi sang file PDF (.pdf) chuẩn 100%
        bằng Microsoft Word Engine để phục vụ xem trước và in ấn.
        Đã tích hợp cơ chế Cache PDF để phản hồi tức thì trong 0ms khi chuyển đổi giữa các mẫu.
        """
        template_path = self._resolve_template_path(template_filename)
        cache_hash = self._get_cache_hash(template_path, person_data)
        clean_tpl = template_filename.replace(".docx", "")
        cached_pdf_name = f"{clean_tpl}_{person_data.id}_{cache_hash}.pdf"
        cached_pdf_path = os.path.join(self.cache_dir, cached_pdf_name)

        # KIỂM TRA BỘ NHỚ ĐỆM (CACHE HIT)
        if os.path.exists(cached_pdf_path) and os.path.getsize(cached_pdf_path) > 0:
            return cached_pdf_path

        # NẾU CHƯA CÓ TRONG CACHE -> RENDER VÀ CONVERT
        docx_path = self.generate_docx_from_person(template_filename, person_data)

        # Khởi tạo COM Apartment cho môi trường đa luồng của FastAPI trên Windows
        if sys.platform == "win32":
            try:
                import pythoncom
                pythoncom.CoInitialize()
            except Exception as e:
                print(f"pythoncom.CoInitialize warning: {e}")

        try:
            from docx2pdf import convert
            convert(docx_path, cached_pdf_path)
        except Exception as e:
            print(f"Error converting docx to pdf: {e}")
            raise RuntimeError(f"Lỗi chuyển đổi Word sang PDF: {e}")

        if not os.path.exists(cached_pdf_path):
            raise FileNotFoundError(f"Không thể tạo file PDF: {cached_pdf_path}")

        return cached_pdf_path

    def clear_person_cache(self, person_id: str):
        """Xóa toàn bộ file cache PDF cũ của đối tượng khi cập nhật thông tin"""
        try:
            if os.path.exists(self.cache_dir):
                for filename in os.listdir(self.cache_dir):
                    if person_id in filename:
                        file_path = os.path.join(self.cache_dir, filename)
                        try:
                            os.remove(file_path)
                        except Exception:
                            pass
        except Exception as e:
            print(f"Error clearing cache for person {person_id}: {e}")
