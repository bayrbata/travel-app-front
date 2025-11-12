# Travel Gallery - Flutter App

Аяллын зураг хадгалах Flutter апп. Travel Gallery сервертэй хамтран ажиллана.

## Онцлогууд

✅ **CRUD үйлдлүүд** - Аяллын зургийг нэмэх, засах, устгах, харах
✅ **Хайлт** - Хот/улс/байршлын нэрээр хайх
✅ **Эрэмбэлэх** - Огноо, гарчиг, байршлаар эрэмбэлэх (өсөх/буурах)
✅ **Grid View** - Зургуудыг grid хэлбэрээр харуулах
✅ **Hero Animation** - Зургийг дэлгэрэнгүй хуудас руу шилжихдээ animation
✅ **Fade Animation** - Зургийн fade-in animation
✅ **Scale Animation** - Зургийн preview-ийн scale animation
✅ **2+ хуудас** - Нүүр хуудас, дэлгэрэнгүй хуудас, нэмэх/засах хуудас

## Суулгах

```bash
flutter pub get
```

## Тохиргоо

### API Service тохиргоо

`lib/services/api_service.dart` файл дээр API-ийн base URL-ийг тохируулна:

- **Android эмулятор**: `http://10.0.2.2:2000` (одоогийн тохиргоо)
- **iOS эмулятор эсвэл physical device**: 
  - `http://localhost:2000` (iOS эмулятор)
  - `http://YOUR_COMPUTER_IP:2000` (physical device)

Physical device дээр ажиллуулахдаа:
1. Компьютер дээр серверийг ажиллуулах
2. Компьютерийн IP хаягийг олох (WiFi дээр)
3. `api_service.dart` файл дээр IP хаягийг оруулах
4. Сервер дээр firewall-ийг шалгах (2000 порт нээлттэй байх ёстой)

## Ажиллуулах

```bash
flutter run
```

## Сервер тохиргоо

Энэ апп нь `travel-app-server` сервертэй хамтран ажиллана. Серверийг эхлүүлэх:

```bash
cd ../travel-app-server
npm install
npm start
```

Сервер `http://localhost:2000` дээр ажиллана.

## Хуудаснууд

### 1. Нүүр хуудас (HomeScreen)
- Аяллын зургуудыг grid хэлбэрээр харуулах
- Хайлтын функц
- Эрэмбэлэх функц (огноо, гарчиг, байршлаар)
- Pull-to-refresh
- Зургийг дарж дэлгэрэнгүй хуудас руу шилжих

### 2. Дэлгэрэнгүй хуудас (TravelDetailScreen)
- Аяллын зургийн дэлгэрэнгүй мэдээлэл
- Засах, устгах үйлдлүүд
- Hero animation (зураг нэг хуудаснаас нөгөө рүү шилжих)

### 3. Нэмэх/Засах хуудас (AddEditTravelScreen)
- Шинэ аяллын зураг нэмэх
- Байгаа аяллын зургийг засах
- Зураг сонгох, тайлбар нэмэх
- Scale animation (зургийн preview)

## Animation-ууд

1. **Hero Animation** - Зургийг grid-ээс дэлгэрэнгүй хуудас руу шилжихдээ smooth transition
2. **Fade Animation** - Зургууд харагдахдаа fade-in animation
3. **Scale Animation** - Зургийн preview-ийн scale animation (Add/Edit хуудас)

## Шаардлага

- Flutter SDK ^3.9.2
- Dart SDK
- Travel Gallery Server (travel-app-server)

## Dependencies

- `http` - API холболт
- `image_picker` - Зураг сонгох
- `flutter_image_compress` - Зургийг шахах
- `convert` - Base64 хөрвүүлэлт

## API Endpoints

Апп нь дараах API endpoint-уудыг ашиглана:

- `GET /api/travels` - Бүх аяллын зургуудыг авах
- `GET /api/travels/:id` - ID-аар нэг зургийг авах
- `POST /api/travels` - Шинэ зургийн мэдээлэл нэмэх
- `PUT /api/travels/:id` - Зургийн мэдээлэл засах
- `DELETE /api/travels/:id` - Зургийн мэдээлэл устгах
- `GET /api/travels/search/:keyword` - Тэмдэгтээр хайх

## Хөгжүүлэлт

### Файлын бүтэц

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── travel_model.dart     # Travel model
├── screens/
│   ├── home_screen.dart      # Нүүр хуудас
│   ├── travel_detail_screen.dart  # Дэлгэрэнгүй хуудас
│   └── add_edit_travel_screen.dart # Нэмэх/Засах хуудас
└── services/
    └── api_service.dart      # API service
```

## Тэмдэглэл

- Android эмулятор дээр `10.0.2.2` нь localhost-ийг илэрхийлнэ
- Physical device дээр компьютер дээрх IP хаягийг ашиглах шаардлагатай
- Зургууд base64 форматтайгаар хадгалагдана
- Зургийг нэмэхдээ автоматиар шахагдана (quality: 88)
