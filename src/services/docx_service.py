import io
import json
import os
import sys
import hashlib
from typing import Optional
import subprocess
from docxtpl import DocxTemplate, InlineImage
from docx.shared import Mm
from src.schemas.document_schema import PersonData, CaseData
from src.config import BASE_DIR, TEMPLATES_DIR, CACHE_DIR


class BaseDocxService:
    """
    Lớp dịch vụ cơ sở quản lý thư mục mẫu, thư mục cache và logic chuyển đổi PDF.
    """

    def __init__(self, template_dir: Optional[str] = None):
        if template_dir is None:
            self.template_dir = TEMPLATES_DIR
        elif os.path.isabs(template_dir):
            self.template_dir = template_dir
        else:
            self.template_dir = os.path.join(BASE_DIR, template_dir)

        self.cache_dir = CACHE_DIR
        os.makedirs(self.cache_dir, exist_ok=True)

    def _convert_docx_to_pdf(self, temp_docx_path: str, cached_pdf_path: str) -> None:
        """
        Chuyển đổi file DOCX sang PDF:
        - Trên Windows: Sử dụng Microsoft Word COM qua thư viện docx2pdf
        - Trên Linux / Docker: Sử dụng LibreOffice headless (soffice)
        """
        if sys.platform == "win32":
            try:
                import pythoncom
                pythoncom.CoInitialize()
            except Exception as e:
                print(f"pythoncom.CoInitialize warning: {e}")

            try:
                from docx2pdf import convert
                convert(temp_docx_path, cached_pdf_path)
            except Exception as e:
                print(f"Error converting docx to pdf via docx2pdf on Windows: {e}")
                raise RuntimeError(f"Lỗi chuyển đổi Word sang PDF: {e}")
        else:
            try:
                cmd = ["soffice", "--headless", "--convert-to", "pdf", "--outdir", self.cache_dir, temp_docx_path]
                res = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
                base_name = os.path.splitext(os.path.basename(temp_docx_path))[0] + ".pdf"
                generated_pdf = os.path.join(self.cache_dir, base_name)
                if os.path.exists(generated_pdf):
                    if generated_pdf != cached_pdf_path:
                        if os.path.exists(cached_pdf_path):
                            os.remove(cached_pdf_path)
                        os.rename(generated_pdf, cached_pdf_path)
                else:
                    raise RuntimeError(f"LibreOffice không tạo được file PDF. Output: {res.stderr}")
            except Exception as e:
                print(f"Error converting docx to pdf via LibreOffice on Linux: {e}")
                raise RuntimeError(f"Lỗi chuyển đổi Word sang PDF trên Linux: {e}")


class PersonDocxService(BaseDocxService):
    """
    Dịch vụ xử lý xuất văn bản và tạo bản xem trước cấp Cá Nhân (Person Level).
    """

    def _resolve_template_path(self, template_filename: str) -> str:
        return os.path.join(self.template_dir, "person", template_filename)

    def _get_cache_hash(self, template_path: str, person_data: PersonData) -> str:
        person_data_str = json.dumps(person_data.model_dump(), sort_keys=True)
        tpl_mtime = str(os.path.getmtime(template_path)) if os.path.exists(template_path) else ""
        raw_key = f"{person_data_str}_{tpl_mtime}"
        return hashlib.md5(raw_key.encode('utf-8')).hexdigest()[:12]

    def get_templates(self) -> list[dict[str, str]]:
        """
        Lấy danh sách các mẫu văn bản dành cho đối tượng từ metadata.json trong templates/person/
        """
        metadata_path = os.path.join(self.template_dir, "person", "metadata.json")
        try:
            with open(metadata_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                if isinstance(data, list):
                    return data
                raise ValueError(f"metadata.json không đúng định dạng list: {type(data)}")
        except Exception as e:
            raise e

    def _render_doc(self, template_filename: str, person_data: PersonData) -> DocxTemplate:
        template_path = self._resolve_template_path(template_filename)
        if not os.path.exists(template_path):
            raise FileNotFoundError(f"Không tìm thấy file docx mẫu cá nhân: {template_path}")

        template_doc = DocxTemplate(template_path)

        # Nạp ảnh đại diện nếu có
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
        return template_doc

    def generate_docx_bytes(self, template_filename: str, person_data: PersonData) -> io.BytesIO:
        """Render tài liệu Word cá nhân trực tiếp vào bộ nhớ RAM"""
        template_doc = self._render_doc(template_filename, person_data)
        buffer = io.BytesIO()
        template_doc.save(buffer)
        buffer.seek(0)
        return buffer

    def generate_pdf(self, template_filename: str, person_data: PersonData, force: bool = False) -> str:
        """Render và chuyển đổi sang PDF cho cá nhân (kèm Cache)"""
        template_path = self._resolve_template_path(template_filename)
        cache_hash = self._get_cache_hash(template_path, person_data)
        clean_tpl = template_filename.replace(".docx", "")
        cached_pdf_name = f"person_{clean_tpl}_{person_data.id}_{cache_hash}.pdf"
        cached_pdf_path = os.path.join(self.cache_dir, cached_pdf_name)

        if not force and os.path.exists(cached_pdf_path) and os.path.getsize(cached_pdf_path) > 0:
            return cached_pdf_path

        temp_docx_name = f"temp_person_{person_data.id}_{cache_hash}.docx"
        temp_docx_path = os.path.join(self.cache_dir, temp_docx_name)

        template_doc = self._render_doc(template_filename, person_data)
        template_doc.save(temp_docx_path)

        try:
            self._convert_docx_to_pdf(temp_docx_path, cached_pdf_path)
        finally:
            if os.path.exists(temp_docx_path):
                try:
                    os.remove(temp_docx_path)
                except Exception:
                    pass

        if not os.path.exists(cached_pdf_path):
            raise FileNotFoundError(f"Không thể tạo file PDF cá nhân: {cached_pdf_path}")

        return cached_pdf_path

    def clear_cache(self, person_id: str):
        """Xóa cache PDF cũ của cá nhân"""
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

    # Aliases for backward compatibility
    def get_person_templates(self):
        return self.get_templates()

    def generate_pdf_from_person(self, template_filename: str, person_data: PersonData, force: bool = False):
        return self.generate_pdf(template_filename, person_data, force)

    def clear_person_cache(self, person_id: str):
        return self.clear_cache(person_id)


class CaseDocxService(BaseDocxService):
    """
    Dịch vụ xử lý xuất văn bản và tạo bản xem trước cấp Toàn Bộ Vụ Án (Case Level).
    """

    def _resolve_template_path(self, template_filename: str) -> str:
        return os.path.join(self.template_dir, "case", template_filename)

    def _get_cache_hash(self, template_path: str, case_data: CaseData) -> str:
        case_dict = {
            "id": case_data.id,
            "ten_tom_tat": case_data.ten_tom_tat,
            "ten_day_du": case_data.ten_day_du,
            "updated_at": case_data.updated_at,
            "persons": [p.model_dump() for p in case_data.con_nguoi_list]
        }
        case_data_str = json.dumps(case_dict, sort_keys=True)
        tpl_mtime = str(os.path.getmtime(template_path)) if os.path.exists(template_path) else ""
        raw_key = f"{case_data_str}_{tpl_mtime}"
        return hashlib.md5(raw_key.encode('utf-8')).hexdigest()[:12]

    def get_templates(self) -> list[dict[str, str]]:
        """
        Lấy danh sách các mẫu văn bản dành cho vụ án từ metadata.json trong templates/case/
        """
        metadata_path = os.path.join(self.template_dir, "case", "metadata.json")
        try:
            with open(metadata_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                if isinstance(data, list):
                    return data
                raise ValueError(f"metadata.json không đúng định dạng list: {type(data)}")
        except Exception as e:
            raise e

    def _render_doc(self, template_filename: str, case_data: CaseData) -> DocxTemplate:
        template_path = self._resolve_template_path(template_filename)
        if not os.path.exists(template_path):
            raise FileNotFoundError(f"Không tìm thấy file docx mẫu vụ việc: {template_path}")

        template_doc = DocxTemplate(template_path)

        persons_list = [p.model_dump() for p in case_data.con_nguoi_list]
        context = {
            "case": {
                "id": case_data.id,
                "ten_tom_tat": case_data.ten_tom_tat,
                "ten_day_du": case_data.ten_day_du,
                "created_at": case_data.created_at,
                "updated_at": case_data.updated_at,
            },
            "con_nguoi_list": persons_list,
        }

        template_doc.render(context)
        return template_doc

    def generate_docx_bytes(self, template_filename: str, case_data: CaseData) -> io.BytesIO:
        """Render tài liệu Word vụ việc trực tiếp vào bộ nhớ RAM"""
        template_doc = self._render_doc(template_filename, case_data)
        buffer = io.BytesIO()
        template_doc.save(buffer)
        buffer.seek(0)
        return buffer

    def generate_pdf(self, template_filename: str, case_data: CaseData, force: bool = False) -> str:
        """Render và chuyển đổi sang PDF cho vụ án (kèm Cache)"""
        template_path = self._resolve_template_path(template_filename)
        cache_hash = self._get_cache_hash(template_path, case_data)
        clean_tpl = template_filename.replace(".docx", "")
        cached_pdf_name = f"case_{clean_tpl}_{case_data.id}_{cache_hash}.pdf"
        cached_pdf_path = os.path.join(self.cache_dir, cached_pdf_name)

        if not force and os.path.exists(cached_pdf_path) and os.path.getsize(cached_pdf_path) > 0:
            return cached_pdf_path

        temp_docx_name = f"temp_case_{case_data.id}_{cache_hash}.docx"
        temp_docx_path = os.path.join(self.cache_dir, temp_docx_name)

        template_doc = self._render_doc(template_filename, case_data)
        template_doc.save(temp_docx_path)

        try:
            self._convert_docx_to_pdf(temp_docx_path, cached_pdf_path)
        finally:
            if os.path.exists(temp_docx_path):
                try:
                    os.remove(temp_docx_path)
                except Exception:
                    pass

        if not os.path.exists(cached_pdf_path):
            raise FileNotFoundError(f"Không thể tạo file PDF vụ việc: {cached_pdf_path}")

        return cached_pdf_path

    def clear_cache(self, case_id: str):
        """Xóa cache PDF cũ của vụ án"""
        try:
            if os.path.exists(self.cache_dir):
                for filename in os.listdir(self.cache_dir):
                    if case_id in filename:
                        file_path = os.path.join(self.cache_dir, filename)
                        try:
                            os.remove(file_path)
                        except Exception:
                            pass
        except Exception as e:
            print(f"Error clearing cache for case {case_id}: {e}")
