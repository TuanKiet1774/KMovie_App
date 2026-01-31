import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String category;

  const CategoryChip({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 12,
          color: Colors.red[300],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}