# Pet Tracker

Evcil dostunun sağlık ve bakım planı tek uygulamada.

Pet Tracker, evcil hayvan sahiplerinin aşı, ilaç, bakım, kilo ve veteriner süreçlerini tek yerden takip edebilmesi için geliştirilen bir Flutter uygulamasıdır.

## Öne Çıkan Özellikler

- Evcil hayvan profili oluşturma
- Aşı takibi ve yaklaşan doz mantığı
- İlaç takibi, günlük log ve bildirim aksiyonları
- Bakım rutinleri ve hatırlatmalar
- Veteriner ziyaretleri, adres ve telefon bilgileri
- PDF sağlık özeti ve paylaşım akışları
- Pati Pasaportu ile seyahat hazırlık checklist’i
- Semptom günlüğü ve veteriner hazırlık notları
- Bakıcı erişimi için yerel MVP akışı

## Kullanılan Teknolojiler

- Flutter
- Dart
- sqflite
- flutter_local_notifications
- share_plus
- pdf
- url_launcher

## Projeyi Çalıştırma

```bash
cd /Users/goker/Pet_Tracker/pet_tracker
flutter pub get
flutter run
```

iOS simulator için:

```bash
flutter run -d "iPhone 17"
```

## Release Dokümanları

- Launch öncesi checklist: [RELEASE_CHECKLIST_TR.md](./RELEASE_CHECKLIST_TR.md)
- Launch durum özeti: [RELEASE_STATUS_TR.md](./RELEASE_STATUS_TR.md)

## Ekran Görüntüleri

> Not: Görselleri `assets/screenshots/` klasörüne aşağıdaki dosya adlarıyla eklediğinde bu bölüm otomatik düzgün görünür.

### Dashboard

![Dashboard](./assets/screenshots/dashboard.png)

### Profil

![Profil](./assets/screenshots/profile.png)

### Akıllı Araçlar ve Modüller

![Akıllı Araçlar](./assets/screenshots/smart_tools.png)
![Modüller](./assets/screenshots/modules.png)

### Bakıcı Erişimi

![Bakıcı Erişimi](./assets/screenshots/caregiver.png)

### Belgeler

![Belgeler](./assets/screenshots/documents.png)

### Pati Pasaportu

![Pati Pasaportu](./assets/screenshots/travel_mode.png)

### Semptom Günlüğü

![Semptom Günlüğü](./assets/screenshots/symptoms.png)

### Veteriner

![Veteriner Ziyaretleri](./assets/screenshots/vet_visits.png)
![Yeni Ziyaret Ekle](./assets/screenshots/vet_add_visit.png)

## Durum

- Bu repo aktif geliştirme aşamasındadır.
- Launch öncesi son doğrulamalar için release dokümanları kullanılmalıdır.

## Notlar

- Kamera ile otomatik OCR’dan aşı tarihi okuma özelliği launch sonrası daha sağlam bir sürümle geri eklenecek.
- Pati Pasaportu şu an hızlı hazırlık rehberi olarak çalışır; resmi ülke / havayolu kural doğrulamasının yerini almaz.
