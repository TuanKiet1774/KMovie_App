# K-Movie - Ứng Dụng Xem Phim Trực Tuyến Hiện Đại

<p align="center">
  <img src="assets/icons/logoapp.png" alt="K-Movie Logo" width="130" style="border-radius: 26px; box-shadow: 0 8px 24px rgba(229, 9, 20, 0.4);" />
</p>

<p align="center">
  <b>Thế giới điện ảnh đỉnh cao trong tầm tay bạn</b><br>
  Trải nghiệm xem phim trực tuyến mượt mà, giao diện Dark Theme sang trọng chuẩn điện ảnh, xây dựng trên nền tảng Flutter & GetX.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-v3.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/GetX-v4.7.2-8A2BE2?style=for-the-badge&logo=flutter&logoColor=white" alt="GetX" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-brightgreen?style=for-the-badge" alt="Platform" />
</p>

---

## Giới Thiệu Tổng Quan

**K-Movie** là ứng dụng di động xem phim trực tuyến đa nền tảng miễn phí, được thiết kế theo phong cách giao diện tối (Dark Theme) hiện đại, mang lại cảm giác rạp chiếu phim chuyên nghiệp tương tự Netflix hay Disney+.

---

## Tính Năng

### 1. Trang Chủ & Khám Phá Phim
- **Banner Slider Tự Động:** Trình chiếu những bộ phim hot mới cập nhật theo chu kỳ mượt mà vô tận.
- **Phân Loại Đa Dạng:** Hiển thị phim theo các nhóm chủ đề hấp dẫn: Phim mới cập nhật, Phim bộ, Phim lẻ, Hoạt hình/Anime.
- **Khám Phá Theo Thể Loại:** Xem danh sách phim chi tiết theo hơn 15+ thể loại (Hành Động, Cổ Trang, Tình Cảm, Viễn Tưởng, Tâm Lý, v.v.).
- **Kéo Để Làm Mới (Pull-to-Refresh):** Cập nhật dữ liệu phim mới nhất nhanh chóng chỉ với một thao tác vuốt.

### 2. Tìm Kiếm & Bộ Lọc Linh Hoạt
- **Tìm Kiếm Real-time với Debounce (800ms):** Tối ưu hóa số lượng truy vấn mạng, phản hồi tức thì khi người dùng gõ từ khóa.
- **Bộ Lọc Thể Loại Thông Minh:** Nút popup icon 4 ô lưới trực quan mở danh sách chọn nhanh kết hợp cùng thanh trượt ngang tiện dụng.
- **Gợi Ý & Cuộn Vô Hạn (Infinite Scroll):** Hiển thị danh sách gợi ý phim mới nhất khi chưa nhập từ khóa và tự động tải thêm trang tiếp theo khi cuộn xuống cuối màn hình.

### 3. Chi Tiết Phim Toàn Diện
- **Giao Diện Parallax Đỉnh Cao:** Ảnh Poster tràn viền kết hợp dải gradient tối sang trọng.
- **Nút Xem Sau Thông Minh:** Tự động chuyển đổi mượt mà giữa biểu tượng **Đã lưu (Bookmark)** và **Thùng rác đỏ** khi phim đã có trong danh sách, hỗ trợ xóa nhanh kèm hộp thoại xác nhận an toàn.
- **Thông Số Rõ Ràng:** Năm phát hành, chất lượng (HD/FHD), ngôn ngữ (Vietsub / Thuyết minh), thẻ thể loại viền đỏ bắt mắt.
- **Tóm Tắt Nội Dung Linh Hoạt:** Đọc tóm tắt phim với tính năng "Xem thêm / Thu gọn" khi nội dung dài quá 5 dòng.
- **Thông Tin Sản Xuất:** Hiển thị rõ ràng Đạo diễn, Dàn diễn viên, Quốc gia sản xuất.
- **Trạng Thái Tập Đã Xem:** Tự động đánh dấu màu cam kèm biểu tượng tích tròn cho các tập phim đã xem.

### 4. Trình Phát Video Cao Cấp (HLS Player)
- **Truyền Phát Video HLS (.m3u8):** Tối ưu hóa khả năng thích ứng băng thông và chất lượng hình ảnh sắc nét.
- **Chuyển Đổi Màn Hình Ngang/Dọc Mượt Mà:** Chế độ ngang (Landscape Immersive) và Chế độ dọc (Portrait Mode).
- **Cử Chỉ Chạm Đúp (Double-Tap Seek):** Chạm đúp 2 bên màn hình để tua tới/lùi 10 giây nhanh chóng kèm hiệu ứng icon mờ dần.
- **Tùy Chỉnh Tốc Độ Phát:** Điều chỉnh từ `0.25x` đến `2.0x`.
- **Tự Động Đếm Ngược Chuyển Tập:** Banner thông báo đếm ngược 20 giây cuối phim để tự động phát tập kế tiếp (hỗ trợ nút hủy hoặc phát ngay).
- **Lưu Tiến Trình Phát Thông Minh:** Tự động lưu vị trí phút:giây đã xem vào `SharedPreferences`, nhắc người dùng tiếp tục xem đúng đoạn dở dang khi quay lại.

### 5. Danh Sách Xem Sau & Đồng Bộ Cloud
- **Tìm Kiếm & Lọc Nội Bộ:** Dễ dàng tìm kiếm và lọc theo thể loại ngay trong danh sách xem sau của bạn.
- **Xóa Nhanh Đa Dạng:** Xóa bằng icon thùng rác trực tiếp hoặc vuốt trượt thẻ phim (Dismissible).
- **Tự Động Dọn Rác Bộ Nhớ:** Tự động xóa sạch lịch sử xem và vị trí phát của phim khi phim bị xóa khỏi danh sách Xem Sau.


---

## Cấu Trúc Thư Mục Dự Án

```plaintext
kmovie/
├── android/                         
├── ios/                             
├── assets/                          
├── lib/                            
│   ├── controllers/                 
│   │   ├── connectivity_controller.dart # Giám sát trạng thái kết nối Internet
│   │   └── movie_controller.dart        # Quản lý dữ liệu phim, danh sách xem sau, tập đã xem
│   ├── models/                      
│   │   ├── episode.dart             # Model Server & EpisodeData 
│   │   ├── movie.dart               # Model thông tin phim cơ bản & làm sạch thẻ HTML
│   │   └── movie_detail.dart        # Model chi tiết phim (đạo diễn, diễn viên, quốc gia, server)
│   ├── screens/                     
│   │   ├── splash_screen.dart       # Màn hình Splash khởi động ứng dụng
│   │   ├── main_screen.dart         # Màn hình gốc điều hướng Bottom Navigation & PopScope
│   │   ├── home_screen.dart         # Trang chủ: Banner Slider, danh mục phim, lọc thể loại
│   │   ├── category_movie_list_screen.dart # Danh sách phim theo thể loại với phân trang vô hạn
│   │   ├── search_screen.dart       # Tìm kiếm phim real-time, gợi ý & bộ lọc
│   │   ├── movie_detail_screen.dart # Chi tiết phim, chọn tập, xem sau thông minh
│   │   ├── video_player_screen.dart # Trình phát video chuyên nghiệp m3u8 (ngang/dọc)
│   │   └── watch_later_screen.dart  # Danh sách xem sau (tìm kiếm, lọc & xóa trượt)
│   ├── services/                   
│   │   └── movie_api_service.dart   # Gọi API phim mở & API Backend xem sau
│   ├── widgets/                     
│   │   ├── app_dialogs.dart         # Hộp thoại thông báo, loading, xác nhận thoát, confirm xóa
│   │   ├── app_search_bar.dart      # Thanh tìm kiếm Dark Theme tái sử dụng
│   │   ├── bottom_nav_widget.dart   # Thanh điều hướng BottomNavigationBar tùy biến
│   │   ├── category_chip.dart       # Thẻ hiển thị thể loại phim (nền mờ viền đỏ)
│   │   ├── category_filter_bar.dart # Thanh lọc thể loại ngang kèm nút icon 4 ô lưới
│   │   ├── movie_card.dart          # Thẻ phim hiển thị poster, năm & tên phim
│   │   └── movie_info_chip.dart     # Chip thông tin phụ (năm, chất lượng, ngôn ngữ)
│   └── main.dart                    
├── pubspec.yaml                     
└── README.md                       
```

---

## Công Nghệ & Thư Viện Sử Dụng

| Thư Viện / Gói | Phiên Bản | Mục Đích Sử Dụng |
|---|---|---|
| **Flutter SDK** | `>=3.0.0 <4.0.0` | Framework phát triển ứng dụng di động đa nền tảng |
| **Dart SDK** | `>=3.0.0` | Ngôn ngữ lập trình chính |
| **GetX (`get`)** | `^4.7.2` | State Management, Dependency Injection & Navigation |
| **`video_player`** | `^2.9.5` | Trình phát video gốc hỗ trợ giải mã luồng streaming HLS (.m3u8) |
| **`wakelock_plus`** | `^1.4.0` | Giữ màn hình thiết bị luôn sáng trong suốt thời gian xem phim |
| **`shared_preferences`** | `^2.5.4` | Lưu trữ dữ liệu cục bộ: Device ID, tiến trình phát, tập đã xem |
| **`connectivity_plus`** | `^6.1.1` | Giám sát trạng thái kết nối mạng Internet (WiFi/Mobile) |
| **`http`** | `^1.4.0` | Gửi HTTP requests RESTful API (GET, POST, DELETE) |
| **`uuid`** | `^4.5.1` | Khởi tạo mã định danh duy nhất (UUID v4) cho từng thiết bị |
| **`google_fonts`** | `^8.0.0` | Typography chuẩn hiện đại với phông chữ Google Fonts |
| **`flutter_launcher_icons`** | `^0.13.1` | Công cụ tự động tạo biểu tượng ứng dụng (App Icon) |

---

## Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### Yêu Cầu Môi Trường
- Đã cài đặt **Flutter SDK** phiên bản `>= 3.19.x` (Khuyến nghị bản mới nhất).
- Đã cài đặt **Android Studio** (Android SDK API `>= 21`) hoặc **VS Code** kèm Flutter/Dart extension.
- Thiết bị di động thật (bật USB Debugging) hoặc máy ảo Android Emulator / iOS Simulator.

### Các Bước Thực Hiện

1. **Clone mã nguồn về máy tính:**
   ```bash
   git clone <repository_url>
   cd kmovie
   ```

2. **Cài đặt các gói thư viện phụ thuộc:**
   ```bash
   flutter pub get
   ```

3. **Cập nhật Launcher Icons (nếu cần):**
   ```bash
   dart run flutter_launcher_icons
   ```

4. **Kiểm tra và phân tích mã nguồn:**
   ```bash
   flutter analyze
   ```

5. **Chạy ứng dụng ở chế độ Debug:**
   ```bash
   flutter run
   ```

---

## Đóng Gói & Cài Đặt Bản Release

### 1. Build File APK Release
Để tạo file cài đặt Android APK tối ưu cho việc phát hành:

```bash
flutter build apk --release
```

Sau khi hoàn tất, file APK sẽ nằm tại đường dẫn:
```plaintext
build/app/outputs/flutter-apk/app-release.apk
```

### 2. Cài Đặt Trực Tiếp Lên Thiết Bị Android
Cắm thiết bị Android đã bật USB Debugging vào máy tính và chạy lệnh:
```bash
flutter install
# Hoặc sử dụng adb:
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## Thiết Kế UI/UX & Trải Nghiệm Người Dùng

- **Bảng Màu Chủ Đạo (Color Palette):**
  - **Nền chính (Background):** Đen tuyền `#000000`, xám tối `#0F0F0F`, `#161616`.
  - **Màu điểm nhấn (Accent Color):** Đỏ rực `#FF0000`, đỏ điện ảnh `#E50914`, `Colors.redAccent`.
  - **Màu trạng thái (Status Colors):** Cam `#FFA500` (đã xem), xanh lá `#4CAF50` (kết nối mạng tốt).
- **Một số giao diện:**

<p align="center">
  <img width="100%" alt="K-Movie Preview" src="https://github.com/user-attachments/assets/b21e869d-f035-4562-bf6d-83b56964ad39" style="border-radius: 12px; box-shadow: 0 6px 30px rgba(0,0,0,0.6);" />
</p>
