import io
import json
import os
import sys
import hashlib
import shutil
import subprocess
from typing import Optional, Any
from datetime import datetime
from abc import ABC, abstractmethod
from docxtpl import DocxTemplate, InlineImage
from docx.shared import Mm
import docx.enum.text
import docx.text.paragraph
from src.schemas.document_schema import PersonData, CaseData, CustomDocumentData
from src.config import BASE_DIR, TEMPLATES_DIR, CACHE_DIR


class BaseDocxService(ABC):
    """
    Layer base abstract service quản lý thư mục mẫu, thư mục cache và logic chuyển đổi PDF.
    Mọi service cần kế thừa và hiện thực các abstract method tương ứng.
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

    @abstractmethod
    def _resolve_template_path(self, template_filename: str) -> str:
        """Trả về đường dẫn tuyệt đối đến tệp mẫu Word docx"""
        pass

    @abstractmethod
    def get_templates(self) -> list[dict[str, Any]]:
        """Lấy danh sách các mẫu văn bản từ file metadata.json tương ứng"""
        pass

    @abstractmethod
    def _render_doc(self, template_filename: str, *args, **kwargs) -> DocxTemplate:
        """Nạp dữ liệu vào template và trả về DocxTemplate đã render"""
        pass

    @abstractmethod
    def _get_cache_hash(self, template_path: str, *args, **kwargs) -> str:
        """Tạo mã băm MD5 duy nhất cho dữ liệu và mẫu để quản lý bộ đệm PDF"""
        pass

    @abstractmethod
    def clear_cache(self, target_id: str):
        """Xóa các tệp cache PDF liên quan đến đối tượng/tài liệu"""
        pass

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
                soffice_bin = shutil.which("soffice") or shutil.which("libreoffice") or "soffice"
                cmd = [
                    soffice_bin,
                    "--headless",
                    "--norestore",
                    "--nofirststartwizard",
                    "--nologo",
                    "--convert-to", "pdf",
                    "--outdir", self.cache_dir,
                    temp_docx_path
                ]
                res = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
                base_name = os.path.splitext(os.path.basename(temp_docx_path))[0] + ".pdf"
                generated_pdf = os.path.join(self.cache_dir, base_name)
                if os.path.exists(generated_pdf):
                    if generated_pdf != cached_pdf_path:
                        if os.path.exists(cached_pdf_path):
                            os.remove(cached_pdf_path)
                        os.rename(generated_pdf, cached_pdf_path)
                else:
                    err_msg = res.stderr.strip() if res.stderr else (res.stdout.strip() if res.stdout else "Không có log chi tiết")
                    raise RuntimeError(f"LibreOffice không tạo được file PDF (Mã thoát: {res.returncode}): {err_msg}")
            except Exception as e:
                print(f"Error converting docx to pdf via LibreOffice on Linux: {e}")
                raise RuntimeError(f"Lỗi chuyển đổi Word sang PDF trên Linux: {e}")


class PersonDocxService(BaseDocxService):
    """
    Dịch vụ xử lý xuất văn bản và tạo bản xem trước cấp Cá Nhân / Đối Tượng (Person Level).
    """

    def _resolve_template_path(self, template_filename: str) -> str:
        return os.path.join(self.template_dir, "person", template_filename)

    def _get_cache_hash(self, template_path: str, person_data: PersonData) -> str:
        person_data_str = json.dumps(person_data.model_dump(), sort_keys=True)
        tpl_mtime = str(os.path.getmtime(template_path)) if os.path.exists(template_path) else ""
        raw_key = f"{person_data_str}_{tpl_mtime}"
        return hashlib.md5(raw_key.encode('utf-8')).hexdigest()[:12]

    def get_templates(self) -> list[dict[str, Any]]:
        metadata_path = os.path.join(self.template_dir, "person", "metadata.json")
        if not os.path.exists(metadata_path):
            return []
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

    def clear_cache(self, target_id: str):
        """Xóa cache PDF cũ của cá nhân"""
        try:
            if os.path.exists(self.cache_dir):
                for filename in os.listdir(self.cache_dir):
                    if target_id in filename:
                        file_path = os.path.join(self.cache_dir, filename)
                        try:
                            os.remove(file_path)
                        except Exception:
                            pass
        except Exception as e:
            print(f"Error clearing cache for person {target_id}: {e}")


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

    def get_templates(self) -> list[dict[str, Any]]:
        metadata_path = os.path.join(self.template_dir, "case", "metadata.json")
        if not os.path.exists(metadata_path):
            return []
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

    def clear_cache(self, target_id: str):
        """Xóa cache PDF cũ của vụ án"""
        try:
            if os.path.exists(self.cache_dir):
                for filename in os.listdir(self.cache_dir):
                    if target_id in filename:
                        file_path = os.path.join(self.cache_dir, filename)
                        try:
                            os.remove(file_path)
                        except Exception:
                            pass
        except Exception as e:
            print(f"Error clearing cache for case {target_id}: {e}")


class CustomDocxService(BaseDocxService):
    """
    Dịch vụ xử lý xuất văn bản và tạo bản xem trước cho các Mẫu Biên Bản Tùy Biến (Custom Documents).
    Hỗ trợ truyền động các custom fields cho cả cấp Vụ án (case) và cấp Đối tượng (person).
    """

    def _resolve_template_path(self, template_filename: str, level: str = "case") -> str:
        level_path = os.path.join(self.template_dir, "custom", level, template_filename)
        if os.path.exists(level_path):
            return level_path
        return os.path.join(self.template_dir, "custom", template_filename)

    def _get_cache_hash(
        self,
        template_path: str,
        custom_doc: CustomDocumentData,
        case_data: Optional[CaseData] = None,
        person_data: Optional[PersonData] = None
    ) -> str:
        doc_dict = {
            "id": custom_doc.id,
            "template_file": custom_doc.template_file,
            "title": custom_doc.title,
            "custom_fields": custom_doc.custom_fields,
            "case": case_data.model_dump() if case_data else None,
            "person": person_data.model_dump() if person_data else None
        }
        doc_str = json.dumps(doc_dict, sort_keys=True)
        tpl_mtime = str(os.path.getmtime(template_path)) if os.path.exists(template_path) else ""
        raw_key = f"{doc_str}_{tpl_mtime}"
        return hashlib.md5(raw_key.encode('utf-8')).hexdigest()[:12]

    def get_templates(self, level: str = "case") -> list[dict[str, Any]]:
        """
        Lấy danh sách các mẫu văn bản tùy biến từ templates/custom/{level}/metadata.json
        """
        metadata_path = os.path.join(self.template_dir, "custom", level, "metadata.json")
        if not os.path.exists(metadata_path):
            legacy_path = os.path.join(self.template_dir, "custom", "metadata.json")
            if not os.path.exists(legacy_path):
                return []
            metadata_path = legacy_path

        try:
            with open(metadata_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                if isinstance(data, list):
                    return data
                return []
        except Exception as e:
            print(f"Error loading custom metadata {level}: {e}")
            return []

    def _render_doc(
        self,
        template_filename: str,
        custom_doc: CustomDocumentData,
        case_data: Optional[CaseData] = None,
        person_data: Optional[PersonData] = None,
        level: str = "case"
    ) -> DocxTemplate:
        template_path = self._resolve_template_path(template_filename, level)
        if not os.path.exists(template_path):
            raise FileNotFoundError(f"Không tìm thấy file docx mẫu tùy biến: {template_path}")

        template_doc = DocxTemplate(template_path)

        context: dict[str, Any] = {
            "doc_title": custom_doc.title,
            "ngay_hien_tai": datetime.now().day,
            "thang_hien_tai": datetime.now().month,
            "nam_hien_tai": datetime.now().year,
        }

        # Gộp thông tin vụ án (nếu có)
        if case_data:
            case_dict = case_data.model_dump()
            context["case"] = case_dict

        # Gộp thông tin cá nhân (nếu có)
        if person_data:
            person_dict = person_data.model_dump()

            if person_data.image_path and os.path.exists(person_data.image_path):
                try:
                    img_obj = InlineImage(template_doc, image_descriptor=person_data.image_path, width=Mm(30))
                except Exception as e:
                    print(f"Error loading image into docx: {e}")
                    img_obj = ""
            else:
                img_obj = ""
            person_dict["image"] = img_obj
            context["person"] = person_dict

        # Xử lý các trường custom_fields và tự động chuyển đổi type persons (danh sách ID -> full object), tách dynamic date
        if custom_doc.custom_fields:
            # Tra cứu map person_id -> full dict
            persons_map: dict[str, dict] = {}
            if case_data:
                for p in case_data.con_nguoi_list:
                    persons_map[p.id] = p.model_dump()

            for key, val in custom_doc.custom_fields.items():
                if isinstance(val, list) and len(val) > 0 and isinstance(val[0], str) and val[0] in persons_map:
                    # Chuyển mảng các person_id thành mảng các person dict
                    context[key] = [persons_map[pid] for pid in val if pid in persons_map]
                elif isinstance(val, str) and "/" in val:
                    parts = val.strip().split("/")
                    if len(parts) == 3:
                        d, m, y = parts[0], parts[1], parts[2]
                        # Tự động sinh các biến tiền tố ngay_, thang_, nam_
                        context[key] = val
                        context[f"ngay_{key}"] = d
                        context[f"thang_{key}"] = m
                        context[f"nam_{key}"] = y
                    else:
                        context[key] = val
                else:
                    context[key] = val

        template_doc.render(context)
        return template_doc

    def generate_docx_bytes(
        self,
        template_filename: str,
        custom_doc: CustomDocumentData,
        case_data: Optional[CaseData] = None,
        person_data: Optional[PersonData] = None,
        level: str = "case"
    ) -> io.BytesIO:
        """Render tài liệu Word tùy biến trực tiếp vào bộ nhớ RAM"""
        template_doc = self._render_doc(template_filename, custom_doc, case_data, person_data, level)
        buffer = io.BytesIO()
        template_doc.save(buffer)
        buffer.seek(0)
        return buffer

    def generate_pdf(
        self,
        template_filename: str,
        custom_doc: CustomDocumentData,
        case_data: Optional[CaseData] = None,
        person_data: Optional[PersonData] = None,
        level: str = "case",
        force: bool = False
    ) -> str:
        """Render và chuyển đổi sang PDF cho biên bản tùy biến (kèm Cache)"""
        template_path = self._resolve_template_path(template_filename, level)
        cache_hash = self._get_cache_hash(template_path, custom_doc, case_data, person_data)
        clean_tpl = template_filename.replace(".docx", "")
        cached_pdf_name = f"custom_{level}_{clean_tpl}_{custom_doc.id}_{cache_hash}.pdf"
        cached_pdf_path = os.path.join(self.cache_dir, cached_pdf_name)

        if not force and os.path.exists(cached_pdf_path) and os.path.getsize(cached_pdf_path) > 0:
            return cached_pdf_path

        temp_docx_name = f"temp_custom_{custom_doc.id}_{cache_hash}.docx"
        temp_docx_path = os.path.join(self.cache_dir, temp_docx_name)

        template_doc = self._render_doc(template_filename, custom_doc, case_data, person_data, level)
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
            raise FileNotFoundError(f"Không thể tạo file PDF tùy biến: {cached_pdf_path}")

        return cached_pdf_path

    def get_template_layout(self, template_filename: str, level: str = "case") -> dict[str, Any]:
        """
        Bóc tách cấu trúc tài liệu DOCX (đoạn văn, bảng biểu, căn lề, biến Jinja2) 
        để phục vụ giao diện Tờ văn bản tương tác (Interactive A4 Sheet).
        """
        template_path = self._resolve_template_path(template_filename, level)
        if not os.path.exists(template_path):
            raise FileNotFoundError(f"Không tìm thấy file docx mẫu: {template_path}")

        # Nạp metadata để lấy thông tin chi tiết các trường
        templates_meta = self.get_templates(level)
        matched_meta = next((t for t in templates_meta if t.get("file_name") == template_filename), {})
        fields_list = matched_meta.get("fields", [])
        fields_map = {f.get("name"): f for f in fields_list if isinstance(f, dict) and "name" in f}

        import docx
        import re

        doc = docx.Document(template_path)
        elements: list[dict[str, Any]] = []

        active_loop_var = None
        active_item_var = None
        active_loop_lines: list[str] = []

        for child in doc.element.body:
            if child.tag.endswith('p'):
                p = docx.text.paragraph.Paragraph(child, doc)
                raw_text = p.text.strip()
                if not raw_text:
                    if not active_loop_var:
                        line_sz = float(p.style.font.size.pt) if (p.style and p.style.font and p.style.font.size) else 14.0
                        elements.append({
                            "type": "spacer",
                            "height": max(line_sz, 14.0)
                        })
                    continue



                # Kiểm tra thẻ mở vòng lặp for: {% for item in loop_var %}
                for_match = re.search(r'\{%\s*for\s+(\w+)\s+in\s+([a-zA-Z0-9_]+)\s*%\}', raw_text)
                if for_match:
                    active_item_var = for_match.group(1)
                    active_loop_var = for_match.group(2)
                    active_loop_lines = []
                    continue

                if '{% endfor %}' in raw_text:
                    if active_loop_var:
                        # Phân tích nội dung bên trong vòng lặp để bóc tách các trường item.*
                        subfields = []
                        for line in active_loop_lines:
                            found = re.findall(rf'\{{\{{\s*{active_item_var}\.([a-zA-Z0-9_]+)\s*\}}\}}', line)
                            for f in found:
                                if f not in subfields:
                                    subfields.append(f)

                        field_meta = fields_map.get(active_loop_var, {})

                        if subfields:
                            # Tự động sinh schema nếu metadata chưa có
                            schema = field_meta.get("item_schema")
                            if not schema:
                                schema = [
                                    {
                                        "name": sub,
                                        "label": "Hỏi" if "hoi" in sub.lower() else ("Đáp" if "dap" in sub.lower() or "tra_loi" in sub.lower() else sub.replace("_", " ").title()),
                                        "type": "textarea"
                                    }
                                    for sub in subfields
                                ]
                            list_type = field_meta.get("type", "list")
                            elements.append({
                                "type": list_type,
                                "name": active_loop_var,
                                "field_info": {
                                    "name": active_loop_var,
                                    "label": field_meta.get("label", active_loop_var.replace("_", " ").title()),
                                    "type": list_type,
                                    "item_schema": schema
                                },
                                "headers": [col.get("label", col.get("name", "")) for col in schema]
                            })

                        else:
                            # Không có item.* -> coi là danh sách đối tượng (persons)
                            elements.append({
                                "type": "persons_section",
                                "name": active_loop_var,
                                "field_info": field_meta or {
                                    "name": active_loop_var,
                                    "label": active_loop_var.replace("_", " ").title(),
                                    "type": "persons"
                                }
                            })
                    active_loop_var = None
                    active_item_var = None
                    active_loop_lines = []
                    continue

                # Nếu đang trong vòng lặp thì thu thập các dòng text để phân tích
                if active_loop_var:
                    active_loop_lines.append(raw_text)
                    continue

                # Nếu là dòng trống (Enter không có chữ)
                if not raw_text.strip():
                    line_sz = float(p.style.font.size.pt) if (p.style and p.style.font and p.style.font.size) else 14.0
                    sb = float(p.paragraph_format.space_before.pt) if (p.paragraph_format and p.paragraph_format.space_before) else (float(p.style.paragraph_format.space_before.pt) if (p.style and p.style.paragraph_format and p.style.paragraph_format.space_before) else 0.0)
                    sa = float(p.paragraph_format.space_after.pt) if (p.paragraph_format and p.paragraph_format.space_after) else (float(p.style.paragraph_format.space_after.pt) if (p.style and p.style.paragraph_format and p.style.paragraph_format.space_after) else 0.0)
                    elements.append({
                        "type": "spacer",
                        "height": max(line_sz * 1.2, 14.0) + sb + sa
                    })
                    continue

                # Căn lề
                align = "left"
                if p.alignment == docx.enum.text.WD_ALIGN_PARAGRAPH.CENTER:
                    align = "center"
                elif p.alignment == docx.enum.text.WD_ALIGN_PARAGRAPH.RIGHT:
                    align = "right"
                elif p.alignment == docx.enum.text.WD_ALIGN_PARAGRAPH.JUSTIFY:
                    align = "justify"

                # Spacing trước và sau đoạn văn (pt) - Chỉ lấy khi người dùng tự thiết lập trực tiếp trên đoạn
                sb = float(p.paragraph_format.space_before.pt) if (p.paragraph_format and p.paragraph_format.space_before is not None) else 0.0
                sa = float(p.paragraph_format.space_after.pt) if (p.paragraph_format and p.paragraph_format.space_after is not None) else 0.0
                fli = float(p.paragraph_format.first_line_indent.pt) if (p.paragraph_format and p.paragraph_format.first_line_indent is not None) else 0.0
                li = float(p.paragraph_format.left_indent.pt) if (p.paragraph_format and p.paragraph_format.left_indent is not None) else 0.0


                # Bóc tách character-level formatting để bảo toàn chính xác bold/italic/size/font/sub/sup
                char_styles = []
                for r in p.runs:
                    b = bool(r.bold)
                    it = bool(r.italic)
                    sz = r.font.size.pt if (r.font and r.font.size) else (p.style.font.size.pt if (p.style and p.style.font and p.style.font.size) else 14.0)
                    fn = (r.font.name if (r.font and r.font.name) else (p.style.font.name if (p.style and p.style.font and p.style.font.name) else 'Times New Roman'))
                    sub = bool(r.font.subscript) if (r.font and r.font.subscript) else False
                    sup = bool(r.font.superscript) if (r.font and r.font.superscript) else False
                    for _ in r.text:
                        char_styles.append((b, it, sz, fn, sub, sup))

                # Tách text và biến {{ var }}
                parts = re.split(r'(\{\{[^{}]+\}\})', p.text)
                pos = 0
                runs_out: list[dict[str, Any]] = []

                for part in parts:
                    if not part:
                        continue
                    part_len = len(part)
                    part_styles = char_styles[pos:pos + part_len]
                    pos += part_len

                    tag_match = re.match(r'\{\{\s*([a-zA-Z0-9_]+(\.[a-zA-Z0-9_]+)*)\s*\}\}', part)
                    if tag_match:
                        var_name = tag_match.group(1).strip()
                        field_info = fields_map.get(var_name, {})
                        is_bold = any(s[0] for s in part_styles) if part_styles else False
                        is_italic = any(s[1] for s in part_styles) if part_styles else False
                        sz = part_styles[0][2] if part_styles else 14.0
                        fn = part_styles[0][3] if part_styles else 'Times New Roman'
                        sub = any(s[4] for s in part_styles) if part_styles else False
                        sup = any(s[5] for s in part_styles) if part_styles else False
                        runs_out.append({
                            "type": "field",
                            "name": var_name,
                            "tag": part,
                            "bold": is_bold,
                            "italic": is_italic,
                            "size": sz,
                            "font": fn,
                            "subscript": sub,
                            "superscript": sup,
                            "field_info": field_info
                        })
                    else:
                        curr_text = ""
                        curr_b = None
                        curr_it = None
                        curr_sz = None
                        curr_fn = None
                        curr_sub = None
                        curr_sup = None
                        for idx, ch in enumerate(part):
                            s = part_styles[idx] if idx < len(part_styles) else (False, False, 14.0, 'Times New Roman', False, False)
                            if curr_b is None:
                                curr_b, curr_it, curr_sz, curr_fn, curr_sub, curr_sup = s
                                curr_text = ch
                            elif (curr_b, curr_it, curr_sz, curr_fn, curr_sub, curr_sup) == s:
                                curr_text += ch
                            else:
                                runs_out.append({
                                    "type": "text",
                                    "text": curr_text,
                                    "bold": curr_b,
                                    "italic": curr_it,
                                    "size": curr_sz,
                                    "font": curr_fn,
                                    "subscript": curr_sub,
                                    "superscript": curr_sup
                                })
                                curr_b, curr_it, curr_sz, curr_fn, curr_sub, curr_sup = s
                                curr_text = ch
                        if curr_text:
                            runs_out.append({
                                "type": "text",
                                "text": curr_text,
                                "bold": curr_b,
                                "italic": curr_it,
                                "size": curr_sz,
                                "font": curr_fn,
                                "subscript": curr_sub,
                                "superscript": curr_sup
                            })


                is_para_bold = any(s[0] for s in char_styles) if char_styles else False

                elements.append({
                    "type": "paragraph",
                    "align": align,
                    "bold": is_para_bold,
                    "runs": runs_out,
                    "space_before": sb,
                    "space_after": sa,
                    "first_line_indent": fli,
                    "left_indent": li
                })





            elif child.tag.endswith('tbl'):
                tbl = docx.table.Table(child, doc)
                table_rows: list[list[str]] = []
                table_var_name = ""

                for row in tbl.rows:
                    row_cells = [cell.text.strip() for cell in row.cells]
                    row_text = " ".join(row_cells)
                    loop_match = re.search(r'\{%tr\s+for\s+\w+\s+in\s+([a-zA-Z0-9_]+)\s*%\}', row_text)
                    if loop_match:
                        table_var_name = loop_match.group(1)
                        continue
                    if '{%tr endfor %}' in row_text:
                        continue
                    table_rows.append(row_cells)

                if table_var_name or table_rows:
                    field_info = fields_map.get(table_var_name, {})
                    elements.append({
                        "type": "table",
                        "name": table_var_name,
                        "field_info": field_info,
                        "headers": table_rows[0] if table_rows else [],
                        "rows": table_rows
                    })

        return {
            "template_file": template_filename,
            "display_name": matched_meta.get("display_name", template_filename.replace(".docx", "")),
            "fields": fields_list,
            "elements": elements
        }

    def clear_cache(self, target_id: str):
        """Xóa cache PDF cũ của biên bản tùy biến"""
        try:
            if os.path.exists(self.cache_dir):
                for filename in os.listdir(self.cache_dir):
                    if target_id in filename:
                        file_path = os.path.join(self.cache_dir, filename)
                        try:
                            os.remove(file_path)
                        except Exception:
                            pass
        except Exception as e:
            print(f"Error clearing cache for custom doc {target_id}: {e}")

