import os
import json
import shutil
from typing import Optional
from datetime import datetime
from src.config import CASES_DIR
from src.schemas.document_schema import CaseData, PersonData, CustomDocumentData


class BaseStorageService:
    """
    Class quản lý cấu trúc thư mục và đọc/ghi file case.json.
    """

    def __init__(self, cases_dir: str = CASES_DIR):
        self.cases_dir = cases_dir
        os.makedirs(self.cases_dir, exist_ok=True)

    def _get_case_folder(self, case_id: str) -> str:
        return os.path.join(self.cases_dir, case_id)

    def _get_case_json_path(self, case_id: str) -> str:
        return os.path.join(self._get_case_folder(case_id), "case.json")

    def _get_case_images_folder(self, case_id: str) -> str:
        return os.path.join(self._get_case_folder(case_id), "images")

    def get_case(self, case_id: str) -> Optional[CaseData]:
        """Đọc chi tiết một vụ án từ file case.json"""
        json_path = self._get_case_json_path(case_id)
        if not os.path.exists(json_path):
            return None

        try:
            with open(json_path, "r", encoding="utf-8") as f:
                raw_data = json.load(f)
                return CaseData.model_validate(raw_data)
        except Exception:
            return None

    def save_case(self, case_data: CaseData) -> CaseData:
        """Lưu hoặc cập nhật một vụ án vào file case.json"""
        case_folder = self._get_case_folder(case_data.id)
        os.makedirs(case_folder, exist_ok=True)
        os.makedirs(self._get_case_images_folder(case_data.id), exist_ok=True)

        case_data.updated_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        json_path = self._get_case_json_path(case_data.id)

        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(case_data.model_dump(), f, ensure_ascii=False, indent=2)

        return case_data


class CaseStorageService(BaseStorageService):
    """
    Service lưu trữ và quản lý cấp Vụ án (Case Level).
    """

    def list_cases(self) -> list[dict]:
        """Lấy danh sách tóm tắt tất cả các vụ án hiện có"""
        results = []
        if not os.path.exists(self.cases_dir):
            return results

        for entry in os.listdir(self.cases_dir):
            folder_path = os.path.join(self.cases_dir, entry)
            if os.path.isdir(folder_path):
                json_path = os.path.join(folder_path, "case.json")
                if os.path.exists(json_path):
                    try:
                        with open(json_path, "r", encoding="utf-8") as f:
                            data = json.load(f)
                            ten_tom_tat = data.get("ten_tom_tat") or "Chưa đặt tên"
                            ten_day_du = data.get("ten_day_du") or ""
                            results.append({
                                "id": data.get("id", entry),
                                "ten_tom_tat": ten_tom_tat,
                                "ten_day_du": ten_day_du,
                                "so_luong_nguoi": len(data.get("con_nguoi_list", [])),
                                "so_luong_custom_docs": len(data.get("custom_documents", [])),
                                "created_at": data.get("created_at", ""),
                                "updated_at": data.get("updated_at", "")
                            })
                    except Exception:
                        pass
        return results

    def delete_case(self, case_id: str) -> bool:
        """Xóa toàn bộ thư mục của một vụ án"""
        case_folder = self._get_case_folder(case_id)
        if os.path.exists(case_folder):
            shutil.rmtree(case_folder, ignore_errors=True)
            return True
        return False


class PersonStorageService(BaseStorageService):
    """
    Service lưu trữ và quản lý Đối tượng / Con người trong vụ án (Person Level).
    """

    def add_or_update_person(
        self,
        case_id: str,
        person_data: PersonData,
        image_bytes: Optional[bytes] = None,
        image_ext: str = "jpg"
    ) -> Optional[PersonData]:
        """Thêm mới hoặc cập nhật thông tin một con người vào vụ án"""
        case = self.get_case(case_id)
        if not case:
            return None

        if image_bytes:
            images_folder = self._get_case_images_folder(case_id)
            os.makedirs(images_folder, exist_ok=True)
            img_filename = f"{person_data.id}.{image_ext.lstrip('.')}"
            img_path = os.path.join(images_folder, img_filename)
            with open(img_path, "wb") as f:
                f.write(image_bytes)
            person_data.image_path = img_path

        found = False
        for idx, p in enumerate(case.con_nguoi_list):
            if p.id == person_data.id:
                if not image_bytes and p.image_path:
                    person_data.image_path = p.image_path
                case.con_nguoi_list[idx] = person_data
                found = True
                break

        if not found:
            case.con_nguoi_list.append(person_data)

        self.save_case(case)
        return person_data

    def get_person(self, case_id: str, person_id: str) -> Optional[PersonData]:
        """Lấy thông tin một con người trong vụ án"""
        case = self.get_case(case_id)
        if not case:
            return None
        for p in case.con_nguoi_list:
            if p.id == person_id:
                return p
        return None

    def delete_person(self, case_id: str, person_id: str) -> bool:
        """Xóa một con người khỏi vụ án"""
        case = self.get_case(case_id)
        if not case:
            return False

        original_count = len(case.con_nguoi_list)
        case.con_nguoi_list = [p for p in case.con_nguoi_list if p.id != person_id]

        if len(case.con_nguoi_list) < original_count:
            self.save_case(case)
            return True
        return False

    def get_person_image_bytes(self, case_id: str, person_id: str) -> Optional[bytes]:
        """Đọc dữ liệu nhị phân ảnh đại diện của một con người"""
        person = self.get_person(case_id, person_id)
        if person and person.image_path and os.path.exists(person.image_path):
            with open(person.image_path, "rb") as f:
                return f.read()
        return None


class CustomDocStorageService(BaseStorageService):
    """
    Dịch vụ lưu trữ và quản lý các văn bản custom trong vụ án (Custom Document Level).
    """

    def list_custom_docs(self, case_id: str) -> list[CustomDocumentData]:
        """Lấy danh sách tất cả các văn bản custom trong vụ án"""
        case = self.get_case(case_id)
        if not case:
            return []
        return case.custom_documents

    def get_custom_doc(self, case_id: str, doc_id: str) -> Optional[CustomDocumentData]:
        """Lấy thông tin chi tiết một văn bản custom"""
        case = self.get_case(case_id)
        if not case:
            return None
        for doc in case.custom_documents:
            if doc.id == doc_id:
                return doc
        return None

    def add_or_update_custom_doc(
        self,
        case_id: str,
        doc_data: CustomDocumentData
    ) -> Optional[CustomDocumentData]:
        """Thêm mới hoặc cập nhật thông tin một văn bản custom vào vụ án"""
        case = self.get_case(case_id)
        if not case:
            return None

        doc_data.updated_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        found = False
        for idx, doc in enumerate(case.custom_documents):
            if doc.id == doc_data.id:
                case.custom_documents[idx] = doc_data
                found = True
                break

        if not found:
            case.custom_documents.append(doc_data)

        self.save_case(case)
        return doc_data

    def delete_custom_doc(self, case_id: str, doc_id: str) -> bool:
        """Xóa một văn bản custom khỏi vụ án"""
        case = self.get_case(case_id)
        if not case:
            return False

        original_count = len(case.custom_documents)
        case.custom_documents = [d for d in case.custom_documents if d.id != doc_id]

        if len(case.custom_documents) < original_count:
            self.save_case(case)
            return True
        return False
