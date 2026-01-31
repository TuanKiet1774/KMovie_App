import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final VoidCallback onVoiceSearch;
  final bool isListening;

  const SearchBarWidget({
    Key? key,
    required this.controller,
    required this.onSearch,
    required this.onVoiceSearch,
    this.isListening = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm phim...',
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    controller.clear();
                    onSearch('');
                  },
                ),
              IconButton(
                icon: Icon(Icons.mic, color: Colors.red),
                onPressed: onVoiceSearch,
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Color(0xFF2A2A2A),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: onSearch,
        textInputAction: TextInputAction.search,
      ),
    );
  }
}
