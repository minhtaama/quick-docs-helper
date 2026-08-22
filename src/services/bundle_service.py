import os
import io
import json
import uuid
import zipfile
from typing import Optional, Any
from datetime import datetime
from src.config import TEMPLATES_DIR
from src.schemas.document_schema import CustomDocumentData
from src.services.storage_service import CaseStorageService, PersonStorageService, CustomDocStorageService
from src.services.docx_service import CustomDocxService


class BundleService:
    """
    Dịch vụ quản lý và sinh gói hồ sơ / tài liệu (Document Bundle) 
    kết hợp giữa cấp Vụ án (Case) và cấp Đối tượng (Person).
    """

    def __init__(self):
        self.bundles_file = os.path.join(TEMPLATES_DIR, "bundles.json")
        self.custom_docx_service = CustomDocxService()
        self.case_storage = CaseStorageService()
        self.person_storage = PersonStorageService()
        self.custom_doc_storage = CustomDocStorageService()

    def get_bundles(self) -> list[dict[str, Any]]:
        """Đọc danh sách tất cả các Bundle từ file bundles.json"""
        if not os.path.exists(self.bundles_file):
            return []
        try:
            with open(self.bundles_file, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            print(f"Lỗi khi đọc file bundles.json: {e}")
            return []

    def get_bundle_by_id(self, bundle_id: str) -> Optional[dict[str, Any]]:
        """Tìm một Bundle theo id"""
        bundles = self.get_bundles()
        for b in bundles:
            if b.get("id") == bundle_id:
                return b
        return None

    def get_bundle_layout(self, case_id: str, bundle_id: str) -> Optional[dict[str, Any]]:
        """
        Bóc tách layout của toàn bộ các văn bản A4 trong Bundle dựa trên vụ án cụ thể:
        - Văn bản cấp case -> 1 tờ A4
        - Văn bản cấp person -> Mở rộng thành các tờ A4 tương ứng với từng đối tượng (theo for_each: all, isdt, not_isdt)
        """
        bundle = self.get_bundle_by_id(bundle_id)
        if not bundle:
            return None

        case = self.case_storage.get_case(case_id)
        if not case:
            return None

        con_nguoi_list = case.con_nguoi_list
        expanded_docs: list[dict[str, Any]] = []

        for item in bundle.get("items", []):
            template_path = item.get("template", "")
            scope = item.get("scope", "case")
            preset_values = item.get("preset_values", {})
            for_each = item.get("for_each", "all")

            # Tách filename từ template_path (ví dụ: case/cv_mang_may_tinh.docx -> cv_mang_may_tinh.docx)
            filename = os.path.basename(template_path)

            if scope == "case":
                try:
                    layout = self.custom_docx_service.get_template_layout(filename, level="case")
                    expanded_docs.append({
                        "doc_key": f"case_{filename}",
                        "template_file": filename,
                        "scope": "case",
                        "person_id": None,
                        "person_name": None,
                        "display_name": layout.get("display_name", filename),
                        "preset_values": preset_values,
                        "layout": layout
                    })
                except Exception as e:
                    print(f"Lỗi nạp layout template {filename}: {e}")

            elif scope == "person":
                # Lọc danh sách đối tượng phù hợp theo for_each (all, isdt, not_isdt)
                matched_persons = []
                for p in con_nguoi_list:
                    is_dt = bool(p.isdt)
                    if for_each == "all":
                        matched_persons.append(p)
                    elif for_each == "isdt" and is_dt:
                        matched_persons.append(p)
                    elif for_each == "not_isdt" and not is_dt:
                        matched_persons.append(p)

                for p in matched_persons:
                    try:
                        layout = self.custom_docx_service.get_template_layout(filename, level="person")
                        p_name = p.ho_ten or "Chưa đặt tên"
                        expanded_docs.append({
                            "doc_key": f"person_{filename}_{p.id}",
                            "template_file": filename,
                            "scope": "person",
                            "person_id": p.id,
                            "person_name": p_name,
                            "display_name": f"{layout.get('display_name', filename)} - {p_name}",
                            "preset_values": preset_values,
                            "layout": layout
                        })
                    except Exception as e:
                        print(f"Lỗi nạp layout template person {filename} cho {p.id}: {e}")

        return {
            "bundle_id": bundle_id,
            "bundle_name": bundle.get("name", "Bộ tài liệu"),
            "description": bundle.get("description", ""),
            "case_id": case_id,
            "documents": expanded_docs
        }

    def save_and_render_bundle(
        self,
        case_id: str,
        bundle_id: str,
        documents_data: dict[str, dict[str, Any]],
        bundle_instance_id: Optional[str] = None
    ) -> tuple[bytes, str]:
        """
        Lưu dữ liệu Bundle 2 chiều (Case + Person) và xuất trọn bộ file nén ZIP:
        - documents_data: Map từ doc_key -> custom_fields
        """
        bundle = self.get_bundle_by_id(bundle_id)
        if not bundle:
            raise ValueError(f"Không tìm thấy bundle: {bundle_id}")

        case = self.case_storage.get_case(case_id)
        if not case:
            raise ValueError(f"Không tìm thấy case: {case_id}")

        instance_id = bundle_instance_id or str(uuid.uuid4())
        bundle_name = bundle.get("name", "Bộ tài liệu")
        now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        # Chuẩn bị luồng ZIP
        zip_buffer = io.BytesIO()
        rendered_files_summary: list[dict[str, Any]] = []

        with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zip_file:
            # Lấy layout mở rộng của bundle để biết chính xác từng doc
            bundle_layout = self.get_bundle_layout(case_id, bundle_id)
            if not bundle_layout:
                raise ValueError("Không thể tạo bố cục cho Bundle")

            for doc_item in bundle_layout.get("documents", []):
                doc_key = doc_item["doc_key"]
                template_file = doc_item["template_file"]
                scope = doc_item["scope"]
                person_id = doc_item["person_id"]
                person_name = doc_item["person_name"]
                preset_values = doc_item.get("preset_values", {})

                # Merge preset_values và user_fields
                user_fields = documents_data.get(doc_key, {})
                merged_fields = {**preset_values, **user_fields}

                # 1. Lưu bản ghi 2 chiều vào CustomDocStorageService
                doc_id = str(uuid.uuid4())
                custom_doc = CustomDocumentData(
                    id=doc_id,
                    template_file=template_file,
                    title=doc_item["display_name"],
                    custom_fields=merged_fields,
                    bundle_id=bundle_id,
                    bundle_instance_id=instance_id,
                    bundle_name=bundle_name,
                    created_at=now_str,
                    updated_at=now_str
                )

                person_obj = None
                if scope == "case":
                    self.custom_doc_storage.add_or_update_custom_doc(case_id, custom_doc, person_id=None)
                else:
                    self.custom_doc_storage.add_or_update_custom_doc(case_id, custom_doc, person_id=person_id)
                    person_obj = self.person_storage.get_person(case_id, person_id)

                # 2. Render file Word tương ứng
                buffer = self.custom_docx_service.generate_docx_bytes(
                    template_filename=template_file,
                    custom_doc=custom_doc,
                    case_data=case,
                    person_data=person_obj,
                    level=scope
                )

                # 3. Đặt tên file Word trong ZIP
                clean_title = doc_item["display_name"].replace("/", "-").replace("\\", "-").replace(":", "-")
                zip_entry_name = f"{clean_title}.docx"
                zip_file.writestr(zip_entry_name, buffer.getvalue())

                rendered_files_summary.append({
                    "doc_id": doc_id,
                    "doc_key": doc_key,
                    "title": doc_item["display_name"],
                    "scope": scope,
                    "person_id": person_id,
                    "filename": zip_entry_name
                })

        # 4. Cập nhật lịch sử Bundle vào Case
        updated_case = self.case_storage.get_case(case_id)
        if updated_case:
            bundle_record = {
                "instance_id": instance_id,
                "bundle_id": bundle_id,
                "bundle_name": bundle_name,
                "created_at": now_str,
                "files": rendered_files_summary
            }
            # Thay thế nếu đã có instance_id cũ, hoặc append mới
            updated_case.bundles = [b for b in updated_case.bundles if b.get("instance_id") != instance_id]
            updated_case.bundles.append(bundle_record)
            self.case_storage.save_case(updated_case)

        zip_buffer.seek(0)
        safe_case_name = (case.ten_tom_tat or "Vu_an").replace(" ", "_")
        safe_bundle_name = bundle_name.replace(" ", "_")
        zip_filename = f"{safe_bundle_name}_{safe_case_name}.zip"

        return zip_buffer.getvalue(), zip_filename
