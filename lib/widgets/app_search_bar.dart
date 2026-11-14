import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onSubmitted;
  final String hintText;
  final EdgeInsetsGeometry margin;
  final bool autofocus;

  const AppSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.onClear,
    this.onSubmitted,
    this.hintText = 'Nhập tên phim...',
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 6),
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          suffixIcon: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              if (controller.text.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                    onClear?.call();
                  },
                );
              }
              return const Icon(Icons.search, color: Colors.grey, size: 20);
            },
          ),
        ),
        textInputAction: TextInputAction.search,
      ),
    );
  }
}
