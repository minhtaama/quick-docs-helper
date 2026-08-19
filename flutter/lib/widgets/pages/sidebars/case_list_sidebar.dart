import 'package:flutter/material.dart';

class CaseListSidebar extends StatefulWidget {
  final List<Map<String, dynamic>> cases;
  final String? selectedCaseId;
  final ValueChanged<String> onCaseSelected;
  final VoidCallback onRefresh;
  final VoidCallback onNewCasePressed;
  final Function(String caseId, String currentTenVu, String currentMoTa)?
  onCaseEdited;
  final Future<void> Function(String caseId)? onCaseDeleted;
  final bool isMobile;

  const CaseListSidebar({
    super.key,
    required this.cases,
    required this.selectedCaseId,
    required this.onCaseSelected,
    required this.onRefresh,
    required this.onNewCasePressed,
    this.onCaseEdited,
    this.onCaseDeleted,
    this.isMobile = false,
  });

  @override
  State<CaseListSidebar> createState() => _CaseListSidebarState();
}

class _CaseListSidebarState extends State<CaseListSidebar> {
  final _searchController = TextEditingController();
  String _searchKeyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final filteredCases = widget.cases.where((item) {
      if (_searchKeyword.isEmpty) return true;
      final tenTomTat = (item['ten_tom_tat'] ?? item['ten_vu'] ?? '')
          .toString()
          .toLowerCase();
      final tenDayDu = (item['ten_day_du'] ?? item['mo_ta'] ?? '')
          .toString()
          .toLowerCase();
      final keyword = _searchKeyword.toLowerCase();
      return tenTomTat.contains(keyword) || tenDayDu.contains(keyword);
    }).toList();

    return Container(
      color: widget.isMobile ? Colors.transparent : theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header thanh công cụ
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.folder_outlined, size: 20, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'DANH SÁCH VỤ VIỆC/VỤ ÁN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: widget.onNewCasePressed,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm vụ', style: TextStyle(fontSize: 13)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),

          // Ô tìm kiếm vụ việc
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() => _searchKeyword = val.trim());
              },
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Tìm kiếm theo tên vụ việc...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: primaryColor.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: primaryColor.withValues(alpha: 0.6),
                ),
                suffixIcon: _searchKeyword.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchKeyword = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                filled: true,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Danh sách các vụ việc
          Expanded(
            child: filteredCases.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 40,
                            color: primaryColor.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchKeyword.isNotEmpty
                                ? 'Không tìm thấy vụ việc phù hợp'
                                : 'Chưa có vụ việc nào.\nNhấn "+ Tạo vụ việc" để bắt đầu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: primaryColor.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    itemCount: filteredCases.length,
                    itemBuilder: (context, index) {
                      final item = filteredCases[index];
                      final caseId = item['id'] ?? '';
                      final tenTomTat =
                          item['ten_tom_tat'] ??
                          item['ten_vu'] ??
                          'Vụ việc không tên';
                      final tenDayDu =
                          item['ten_day_du'] ?? item['mo_ta'] ?? '';
                      final soNguoi = item['so_luong_nguoi'] ?? 0;
                      final isSelected = widget.selectedCaseId == caseId;

                      return Card(
                        elevation: isSelected ? 2 : 0,
                        margin: const EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(
                            color: isSelected
                                ? primaryColor
                                : theme.colorScheme.outline.withValues(
                                    alpha: 0.15,
                                  ),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        color: isSelected
                            ? theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.6)
                            : theme.colorScheme.surface,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
                          onTap: () => widget.onCaseSelected(caseId),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.file_copy,
                                            color: primaryColor,
                                            size: 21,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              tenTomTat,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: primaryColor,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (tenDayDu.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          tenDayDu,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: primaryColor.withValues(
                                              alpha: 0.6,
                                            ),
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.people_alt_outlined,
                                            size: 14,
                                            color: primaryColor.withValues(
                                              alpha: 0.7,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$soNguoi đối tượng',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: primaryColor.withValues(
                                                alpha: 0.7,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (widget.onCaseEdited != null)
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: primaryColor.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                    tooltip: 'Chỉnh sửa tên/mô tả vụ việc',
                                    onPressed: () => widget.onCaseEdited!(
                                      caseId,
                                      tenTomTat,
                                      tenDayDu,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
