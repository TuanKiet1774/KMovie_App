import 'package:flutter/material.dart';

class CategoryFilterBar extends StatelessWidget {
  /// Tên thể loại đang được chọn (ví dụ: 'Tất cả', 'Hành Động')
  final String selectedCategory;

  /// Callback khi người dùng chọn một thể loại: trả về (name, slug)
  final void Function(String categoryName, String categorySlug) onCategorySelected;

  /// Danh sách thể loại tùy biến (nếu không truyền sẽ dùng defaultCategories)
  final List<Map<String, String>> categories;

  /// Khoảng cách margin bên ngoài widget
  final EdgeInsetsGeometry margin;

  const CategoryFilterBar({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.categories = defaultCategories,
    this.margin = const EdgeInsets.only(top: 4, bottom: 8),
  });

  /// 15 thể loại chuẩn của hệ thống K-Movie
  static const List<Map<String, String>> defaultCategories = [
    {'name': 'Tất cả', 'slug': 'all'},
    {'name': 'Hành Động', 'slug': 'hanh-dong'},
    {'name': 'Cổ Trang', 'slug': 'co-trang'},
    {'name': 'Viễn Tưởng', 'slug': 'vien-tuong'},
    {'name': 'Tình Cảm', 'slug': 'tinh-cam'},
    {'name': 'Tâm Lý', 'slug': 'tam-ly'},
    {'name': 'Thể Thao', 'slug': 'the-thao'},
    {'name': 'Phiêu Lưu', 'slug': 'phieu-luu'},
    {'name': 'Âm Nhạc', 'slug': 'am-nhac'},
    {'name': 'Gia Đình', 'slug': 'gia-dinh'},
    {'name': 'Học Đường', 'slug': 'hoc-duong'},
    {'name': 'Hài Hước', 'slug': 'hai-huoc'},
    {'name': 'Hình Sự', 'slug': 'hinh-su'},
    {'name': 'Võ Thuật', 'slug': 'vo-thuat'},
    {'name': 'Khoa Học', 'slug': 'khoa-hoc'},
  ];

  /// Tra cứu slug từ tên thể loại
  static String getCategorySlug(String categoryName) {
    for (final item in defaultCategories) {
      if (item['name'] == categoryName) {
        return item['slug'] ?? 'all';
      }
    }
    return 'all';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: margin,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAllCategoriesButton(context);
          }
          final cat = categories[index - 1];
          final name = cat['name'] ?? '';
          final slug = cat['slug'] ?? '';
          final isSelected = name == selectedCategory;
          return _buildCategoryChip(context, name, slug, isSelected);
        },
      ),
    );
  }

  /// Nút icon 4 ô mở modal bottom sheet
  Widget _buildAllCategoriesButton(BuildContext context) {
    final hasFilter = selectedCategory != 'Tất cả';
    return Tooltip(
      message: 'Tất cả thể loại',
      child: InkWell(
        onTap: () => _showCategoriesBottomSheet(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: hasFilter ? Colors.red.withValues(alpha: 0.2) : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasFilter ? Colors.redAccent : Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: hasFilter
                ? [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              Icons.grid_view_rounded,
              color: hasFilter ? Colors.redAccent : Colors.white70,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  /// Từng chip thể loại ngang
  Widget _buildCategoryChip(
    BuildContext context,
    String name,
    String slug,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => onCategorySelected(name, slug),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFE50914), Color(0xFFB81D24)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.redAccent : Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            name,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[300],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  /// BottomSheet dạng lưới 3 cột cân đối cho 15 thể loại
  void _showCategoriesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thanh kéo handle bar
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Header với icon, tiêu đề và nút đóng
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.movie_filter_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tất cả thể loại',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Chọn thể loại phim để lọc nhanh',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF262626),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white70, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Grid 3 cột đều đặn (5 hàng x 3 cột = 15 thể loại)
                Flexible(
                  child: SingleChildScrollView(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: categories.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.3,
                      ),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final name = cat['name'] ?? '';
                        final slug = cat['slug'] ?? '';
                        final isSelected = name == selectedCategory;

                        return InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            onCategorySelected(name, slug);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [Color(0xFFE50914), Color(0xFFB81D24)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : const Color(0xFF222222),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.redAccent.withValues(alpha: 0.8)
                                    : Colors.white.withValues(alpha: 0.08),
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.red.withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.grey[300],
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
