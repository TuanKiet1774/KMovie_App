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
              // Poster phim với overlay
              Expanded(
                child: _buildPosterSection(),
              ),
              // Thông tin phim
              _buildInfoSection(),
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
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              movie.quality,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Xây dựng phần thông tin
  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(12),
      color: Color(0xFF1A1A1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tên phim
          Text(
            movie.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          // Thông tin phụ
          Text(
            '${movie.year} • ${movie.language}',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
