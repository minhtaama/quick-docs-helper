import io
import json
import os
import sys
import hashlib
from typing import Optional
import subprocess
from docxtpl import DocxTemplate, InlineImage
from docx.shared import Mm
from src.schemas.document_schema import PersonData
from src.config import BASE_DIR, TEMPLATES_DIR, CACHE_DIR

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

        self.cache_dir = CACHE_DIR
        os.makedirs(self.cache_dir, exist_ok=True)

    def _resolve_person_template_path(self, template_filename: str) -> str:
        return os.path.join(self.template_dir, "person", template_filename)

    def _get_cache_hash(self, template_path: str, person_data: PersonData) -> str:
        person_data_str = json.dumps(person_data.model_dump(), sort_keys=True)
        tpl_mtime = str(os.path.getmtime(template_path)) if os.path.exists(template_path) else ""
        raw_key = f"{person_data_str}_{tpl_mtime}"
        return hashlib.md5(raw_key.encode('utf-8')).hexdigest()[:12]

    def get_person_templates(self) -> list[dict[str, str]]:
        """
        Lấy danh sách các mẫu văn bản dành cho đối tượng từ metadata.json
        trong thư mục templates/person/
        """
        person_tpl_dir = os.path.join(self.template_dir, "person")
        metadata_path = os.path.join(person_tpl_dir, "metadata.json")
        
        try:
            with open(metadata_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                if isinstance(data, list):
                    return data
                else:
                    raise ValueError(f"metadata.json không có định dạng là list, nhận vào: {type(data)}")
        except Exception as e:
            raise e

    def _render_person_doc(self, template_filename: str, person_data: PersonData) -> DocxTemplate:
        """Hàm nội bộ dựng template DocxTemplate nạp đầy đủ context thuần list[dict]"""
        template_path = self._resolve_person_template_path(template_filename)

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
        return template_doc

    def generate_docx_bytes(self, template_filename: str, person_data: PersonData) -> io.BytesIO:
        """
        Render tài liệu Word trực tiếp vào bộ nhớ RAM (io.BytesIO)
        để phục vụ download trực tiếp mà không cần ghi file ra ổ đĩa.
        """
        template_doc = self._render_person_doc(template_filename, person_data)
        buffer = io.BytesIO()
        template_doc.save(buffer)
        buffer.seek(0)
        return buffer

    def generate_pdf_from_person(self, template_filename: str, person_data: PersonData, force: bool = False) -> str:
        """
        Render file Word tạm rồi chuyển đổi sang file PDF (.pdf) để phục vụ xem trước.
        Sau khi convert xong, file Word tạm sẽ được tự động xóa ngay lập tức để giữ ổ cứng sạch sẽ.
        Đã tích hợp cơ chế Cache PDF để phản hồi tức thì trong 0ms khi chuyển đổi giữa các mẫu.
        """
        template_path = self._resolve_person_template_path(template_filename)
        cache_hash = self._get_cache_hash(template_path, person_data)
        clean_tpl = template_filename.replace(".docx", "")
        cached_pdf_name = f"{clean_tpl}_{person_data.id}_{cache_hash}.pdf"
        cached_pdf_path = os.path.join(self.cache_dir, cached_pdf_name)

        # KIỂM TRA BỘ NHỚ ĐỆM (CACHE HIT - Chỉ dùng khi không yêu cầu force)
        if not force and os.path.exists(cached_pdf_path) and os.path.getsize(cached_pdf_path) > 0:
            return cached_pdf_path

        # NẾU CHƯA CÓ HOẶC BẮT BUỘC RELOAD -> TẠO FILE DOCX TẠM VÀ CONVERT
        temp_docx_name = f"temp_{person_data.id}_{cache_hash}.docx"
        temp_docx_path = os.path.join(self.cache_dir, temp_docx_name)
        
        template_doc = self._render_person_doc(template_filename, person_data)
        template_doc.save(temp_docx_path)

        # Chuyển đổi DOCX sang PDF
        try:
            # Debug trên Windows PC
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
            # Chạy live trên Linux / Docker: Dùng LibreOffice headless
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
        finally:
            # Xóa file Word tạm ngay lập tức sau khi đã có PDF
            if os.path.exists(temp_docx_path):
                try:
                    os.remove(temp_docx_path)
                except Exception:
                    pass

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
