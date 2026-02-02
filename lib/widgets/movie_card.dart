import 'package:flutter/material.dart';

import '../models/movie.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;

  const MovieCard({
    Key? key,
    required this.movie,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Poster phim với overlay (Flex 67%)
              Expanded(
                flex: 2,
                child: _buildPosterSection(),
              ),
              // Thông tin phim (Flex 33%)
              Expanded(
                flex: 1,
                child: _buildInfoSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Xây dựng phần poster
  Widget _buildPosterSection() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Hình ảnh poster
        movie.posterUrl.isNotEmpty
            ? Image.network(
          movie.posterUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('[ERROR] Failed to load poster for: ${movie.name}');
            print('[DEBUG] Poster URL: ${movie.posterUrl}');
            return Container(
              color: Color(0xFF2A2A2A),
              child: Icon(
                Icons.movie,
                size: 50,
                color: Colors.grey,
              ),
            );
          },
        )
            : Container(
          color: Color(0xFF2A2A2A),
          child: Icon(
            Icons.movie,
            size: 50,
            color: Colors.grey,
          ),
        ),
        // Badge chất lượng
      ],
    );
  }

  // Xây dựng phần thông tin
  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Color(0xFF1A1A1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tên phim
          Text(
            movie.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
          ),
          SizedBox(height: 2),
          // Năm
          Text(
            '${movie.year}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[400],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
