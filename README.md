# KMovie - Ứng dụng xem phim trực tuyến 🎬

**K-Movie** là một ứng dụng di động xem phim hiện đại được xây dựng bằng framework **Flutter**, tích hợp nhiều tính năng thông minh giúp người dùng có những giây phút giải trí tuyệt vời nhất.

## ✨ Tính năng nổi bật

- **Xem phim chất lượng cao:** Hỗ trợ trình phát video mượt mà, tùy chỉnh linh hoạt (Chewie & Video Player).
- **Tìm kiếm thông minh:** Tích hợp tính năng tìm kiếm phim bằng **giọng nói** (Speech-to-Text).
- **Danh sách Xem sau:** Dễ dàng lưu lại những bộ phim yêu thích để xem lại sau.
- **Giao diện hiện đại (Dark Mode):** Thiết kế theo phong cách tối giản, sang trọng, tối ưu cho trải nghiệm người dùng ban đêm.

## 🛠 Công nghệ sử dụng

- **Frontend:** Flutter
- **Quản lý trạng thái (State Management):** GetX & Provider
- **Backend/Database:** Nodejs & MongoDB
- **Video Player:** Chewie & Video Player
- **Tiện ích:** Shared Preferences, Permission Handler, Wakelock Plus.

## 📸 Ảnh chụp màn hình

### Logo App

<div align="center"><img width="200" height="200" alt="logoapp" style="border-radius: 10px;" src="https://github.com/user-attachments/assets/89f1e776-c698-4707-ac99-cfe25f63dde9" /></div>

### Demo

![Demo](https://github.com/user-attachments/assets/82e879c6-d95e-4046-a6b9-bc7f7e1b7e9e)

## 🚀 Hướng dẫn cài đặt

Để chạy dự án này trên môi trường local, bạn cần thực hiện các bước sau:

### Điều kiện tiên quyết
- Đã cài đặt [Flutter SDK](https://docs.flutter.dev/get-started/install) (phiên bản >= 3.0.0).
- Đã cài đặt Android Studio / VS Code và emulator hoặc thiết bị thật.

### Các bước thực hiện

1.  **Clone repository:**
    ```bash
    git clone https://github.com/TuanKiet1774/KMovie_App.git
    cd KMovie_App
    ```

2.  **Cài đặt dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Chạy ứng dụng:**
    ```bash
    flutter run
    ```
4. Xuất file apk
    ```bash
    flutter build apk --release
    ```

## 📁 Cấu trúc thư mục

```text
lib/
├── controllers/    # Quản lý logic và trạng thái (GetX)
├── models/         # Định nghĩa các model dữ liệu (Movie, Genre, ...)
├── screens/        # Các màn hình chính (Home, Detail, Player, ...)
├── services/       # Xử lý API và kết nối Supabase
├── widgets/        # Các component UI dùng chung
└── main.dart       # Điểm khởi đầu của ứng dụng
```
