# 🎬 K-Movie - Ứng Dụng Xem Phim Trực Tuyến

<p align="center">
  <img src="assets/icons/logoapp.png" alt="K-Movie Logo" width="120" style="border-radius: 24px; box-shadow: 0 4px 20px rgba(255, 0, 0, 0.3);" />
</p>

<p align="center">
  <b>Thế giới phim trong tầm tay</b><br>
  Ứng dụng xem phim trực tuyến hiện đại, mượt mà trên nền tảng di động được xây dựng bằng Flutter.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/GetX-8A2BE2?style=for-the-badge&logo=flutter&logoColor=white" alt="GetX" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-brightgreen?style=for-the-badge" alt="Platform" />
</p>

---

## Giới Thiệu Tổng Quan

**K-Movie** là một ứng dụng di động xem phim trực tuyến miễn phí với giao diện tối (Dark Theme) sang trọng, mang lại trải nghiệm xem phim chất lượng cao tương tự các nền tảng streaming hàng đầu. Ứng dụng hỗ trợ kho phim phong phú từ nguồn mở, phát video định dạng HLS (m3u8), quản lý danh sách yêu thích/xem sau thông qua Backend riêng và lưu trữ tiến trình xem phim cục bộ.

---

## Tính Năng Nổi Bật

### 1. Trang Chủ & Khám Phá Phim
- **Banner Slider Cuộn Tự Động:** Trình chiếu các phim mới cập nhật với hiệu ứng cuộn mượt mà vô tận.
- **Bộ Lọc Phim Theo Thể Loại:** Dễ dàng lọc phim theo 15+ thể loại đa dạng (Hành Động, Cổ Trang, Viễn Tưởng, Tình Cảm, Tâm Lý, v.v.).
- **Danh Mục Nổi Bật:** Hiển thị danh sách phim theo hàng ngang theo các chủ đề nổi bật cùng nút "Xem thêm".
- **Vuốt Để Làm Mới (Pull-to-Refresh):** Cập nhật dữ liệu phim mới nhất nhanh chóng.

### 2. Tìm Kiếm Thông Minh (Search)
- **Tìm kiếm Real-time với Debounce (800ms):** Tối ưu hóa số lượng truy vấn mạng, phản hồi mượt mà khi người dùng gõ phím.
- **Gợi Ý Phim Mới:** Hiển thị danh sách gợi ý phim mới cập nhật ngay khi chưa nhập từ khóa.
- **Cuộn Vô Hạn (Infinite Scrolling):** Tự động tải thêm phim khi cuộn xuống cuối màn hình gợi ý/kết quả.

### 3. Chi Tiết Phim Đầy Đủ (Movie Details)
- **Giao Diện SliverAppBar Parallax:** Hiển thị Poster cỡ lớn kết hợp gradient đen tinh tế.
- **Thông Tin Toàn Diện:** Tên phim, năm phát hành, chất lượng (HD/FHD), ngôn ngữ/phụ đề, đạo diễn, dàn diễn viên, quốc gia, thời lượng và tóm tắt nội dung.
- **Chọn Server & Tập Phim:** Hỗ trợ chuyển đổi linh hoạt giữa nhiều Server phát (Vietsub, Thuyết minh) và danh sách tập phim trực quan.
- **Đánh Dấu Đã Xem:** Đánh dấu những tập phim đã xem theo thời gian thực.
- **Xem Tiếp (Resume):** Gợi ý tiếp tục xem đúng tập và thời điểm đang xem dở từ lần trước.

### 4. Trình Phát Video Chuyên Nghiệp (Video Player)
- **Hỗ Trợ Streaming HLS (.m3u8):** Tối ưu hóa tốc độ tải và chất lượng phát video.
- **Toàn Màn Hình Tự Động (Landscape Immersive):** Tự động xoay ngang và ẩn thanh điều hướng hệ thống để tập trung xem phim.
- **Chống Tắt Màn Hình (Wakelock):** Màn hình luôn sáng trong suốt quá trình phát video.
- **Cử Chỉ Chạm Đúp (Double-Tap Seek):** Tua tới hoặc tua lui 10 giây nhanh chóng bằng cử chỉ chạm hai bên màn hình.
- **Tùy Chỉnh Tốc Độ Phát:** Điều chỉnh từ 0.25x đến 2.0x.
- **Tự Động Chuyển Tập (Next Episode Countdown):** Đếm ngược 20 giây cuối phim để tự động phát tập kế tiếp (kèm nút hủy hoặc xem ngay).
- **Lưu Lịch Sử & Vị Trí Phát:** Tự động lưu vị trí giây đã xem mỗi 30 giây vào `SharedPreferences`.
- **Tự Phục Hồi Khi Có Mạng Trở Lại:** Tự động phát lại video khi kết nối Internet được khôi phục.

### 5. Danh Sách Xem Sau (Watch Later)
- **Đồng Bộ Thiết Bị:** Sử dụng Device ID duy nhất (UUID) để lưu trữ danh sách phim xem sau lên Backend API độc lập.
- **Thao Tác Vuốt Xóa Tiện Lợi (Slidable Card):** Vuốt thẻ phim sang trái/phải để kích hoạt nút xóa nhanh.
- **Tự Động Dọn Dẹp Dữ Liệu:** Khi xóa phim khỏi Xem Sau, hệ thống tự động dọn sạch lịch sử và vị trí phát của phim đó để tiết kiệm bộ nhớ máy.

### 6. Giám Sát Kết Nối Mạng (Network Connectivity)
- Lắng nghe trạng thái Internet qua `ConnectivityController`.
- Hiển thị Snackbar thông báo trạng thái kết nối.
- Tự động làm mới dữ liệu khi thiết bị có mạng trở lại.

---

## Cấu Trúc Toàn Bộ Dự Án

```plaintext
kmovie/
├── android/                   # Cấu hình dự án cho nền tảng Android (Kotlin DSL)
├── ios/                       # Cấu hình dự án cho nền tảng iOS
├── assets/                    # Tài nguyên tĩnh
├── lib/                       # Toàn bộ mã nguồn ứng dụng (Dart)
│   ├── controllers/           # Quản lý State và Business Logic (GetX)
│   │   ├── connectivity_controller.dart # Giám sát trạng thái mạng Internet
│   │   └── movie_controller.dart        # Quản lý dữ liệu phim, xem sau, lịch sử
│   ├── models/                # Định nghĩa cấu trúc dữ liệu (Data Models)
│   │   ├── episode.dart       # Model cho Server và danh sách Tập phim
│   │   ├── movie.dart         # Model thông tin phim cơ bản & làm sạch HTML
│   │   └── movie_detail.dart  # Model chi tiết phim (diễn viên, đạo diễn, server, tập)
│   ├── screens/               # Các màn hình giao diện (UI Screens)
│   │   ├── splash_screen.dart           # Màn hình Splash khởi động động
│   │   ├── main_screen.dart             # Màn hình gốc chứa Bottom Navigation & PopScope
│   │   ├── home_screen.dart             # Màn hình chính (Banner, danh mục, dropdown lọc)
│   │   ├── category_movie_list_screen.dart # Danh sách phim theo thể loại (phân trang vô hạn)
│   │   ├── search_screen.dart           # Màn hình tìm kiếm & gợi ý phim
│   │   ├── movie_detail_screen.dart     # Chi tiết phim, chọn tập, xem sau
│   │   ├── video_player_screen.dart     # Trình phát video chuyên nghiệp m3u8
│   │   └── watch_later_screen.dart      # Danh sách phim xem sau (thẻ vuốt trượt)
│   ├── services/              # Tương tác với API & Network
│   │   └── movie_api_service.dart       # Service gọi API phim và API backend xem sau
│   ├── widgets/               # Các component UI tái sử dụng
│   │   ├── app_dialogs.dart             # Dialogs (Loading, Error, Toast, Confirm, Exit)
│   │   ├── bottom_nav_widget.dart       # Thanh điều hướng BottomNavigationBar
│   │   ├── category_chip.dart           # Chip hiển thị thể loại phim viền đỏ
│   │   ├── movie_card.dart              # Thẻ hiển thị poster và tên phim
│   │   ├── movie_info_chip.dart         # Chip thông tin phụ (năm, chất lượng)
│   │   └── search_bar_widget.dart       # Ô nhập tìm kiếm tái sử dụng
│   └── main.dart              # Điểm khởi chạy ứng dụng (Entrypoint, App Theme, DI)
├── test/                      # Unit & Widget tests
│   └── widget_test.dart
├── pubspec.yaml               # Danh sách thư viện và cấu hình assets
└── README.md                 
```

---

## Công Nghệ & Thư Viện Sử Dụng

| Thư Viện | Phiên Bản | Mục Đích |
|---|---|---|
| **Flutter SDK** | `>=3.0.0 <4.0.0` | Nền tảng phát triển ứng dụng đa nền tảng |
| **GetX (`get`)** | `^4.7.2` | Quản lý trạng thái (State Management) & Dependency Injection |
| **`video_player`** | `^2.9.5` | Trình phát video hỗ trợ giao thức phát HLS/m3u8 |
| **`wakelock_plus`** | `^1.4.0` | Giữ màn hình luôn sáng khi đang xem phim |
| **`shared_preferences`** | `^2.5.4` | Lưu trữ dữ liệu cục bộ: Device ID, lịch sử xem, vị trí phát từng tập |
| **`connectivity_plus`** | `^6.1.1` | Giám sát trạng thái kết nối mạng Internet |
| **`http`** | `^1.4.0` | Gửi request RESTful API lấy dữ liệu phim và đồng bộ Xem Sau |
| **`uuid`** | `^4.5.1` | Sinh mã định danh thiết bị duy nhất (v4) |
| **`google_fonts`** | `^8.0.0` | Font chữ chuẩn phong cách hiện đại (Outfit, Inter) |
| **`flutter_launcher_icons`** | `^0.13.1` | Tự động sinh icon ứng dụng cho Android & iOS |

---

## Tích Hợp API

Ứng dụng kết hợp giữa dịch vụ dữ liệu phim mở và backend riêng:

1. **Phim - [Link API](https://phimapi.com):**
   - Danh sách phim mới cập nhật: `/danh-sach/phim-moi-cap-nhat`
   - Tìm kiếm phim theo từ khóa: `/v1/api/tim-kiem?keyword={keyword}`
   - Chi tiết phim & danh sách tập streaming: `/phim/{slug}`
   - Danh sách phim theo thể loại/danh mục: `/v1/api/danh-sach/{slug}` hoặc `/the-loai/{slug}`
   - CDN hình ảnh: `https://phimimg.com/`

2. **K-Movie Backend - [KMovie_BE](https://github.com/TuanKiet1774/KMovie_BE.git)**
   - Lưu trữ và quản lý danh sách Xem Sau theo `deviceId`:
     - `POST /watch-later`: Thêm phim vào danh sách.
     - `GET /watch-later/:deviceId`: Lấy danh sách slug phim đã lưu.
     - `DELETE /watch-later`: Xóa phim khỏi danh sách.
     - `GET /watch-later/check/status`: Kiểm tra trạng thái đã lưu hay chưa.

---

## Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### 1. Yêu Cầu Môi Trường
- Đã cài đặt **Flutter SDK** (Khuyến nghị phiên bản `>= 3.19.x` hoặc mới nhất).
- Đã cài đặt **Android Studio** / **VS Code** kèm theo Flutter & Dart Extension.
- Thiết bị thật hoặc máy ảo Android (API level `>= 21`) / iOS Simulator.

### 2. Các Bước Cài Đặt

1. **Clone repository về máy:**
   ```bash
   git clone <repository_url>
   cd kmovie
   ```

2. **Cài đặt các gói phụ thuộc (dependencies):**
   ```bash
   flutter pub get
   ```

3. **Cập nhật Launcher Icons (nếu cần):**
   ```bash
   dart run flutter_launcher_icons
   ```

4. **Chạy ứng dụng ở chế độ Debug:**
   ```bash
   flutter run
   ```
5. Cài app: [K-movie](dowload_app)

---

## Giao Diện & Trải Nghiệm Người Dùng (UI/UX)

- **Màu sắc chủ đạo:** 
  - Nền tối (`#000000`, `#0F0F0F`, `#1A1A1A`) tạo cảm giác rạp chiếu phim chuyên nghiệp.
  - Điểm nhấn đỏ rực rỡ (`#FF0000`, `Colors.redAccent`) tạo phong cách ấn tượng và nổi bật tương tự Netflix.
- **Trải nghiệm điều hướng thông minh:** Tự động điều hướng về màn hình Home trước khi hiển thị hộp thoại xác nhận thoát ứng dụng (`PopScope`).

<img width="2000" height="737" alt="image" src="https://github.com/user-attachments/assets/21c65cb0-4fcd-42ef-bf04-9aecf8447431" />
