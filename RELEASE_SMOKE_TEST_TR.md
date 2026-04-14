# Pet Tracker - Release Smoke Test (TR)

Bu doküman launch öncesi 20-30 dakikalık son doğrulama turu için hazırlanmıştır.

## Test Ortamı

- Cihaz: iPhone 17 Simulator + mümkünse 1 fiziksel iPhone
- Build: Release aday sürümü
- Tarih:
- Test eden:

## Hızlı Senaryo Akışı

1. Uygulama açılışını doğrula.
2. Yeni evcil hayvan ekle.
3. Aşı kaydı ekle.
4. İlaç kaydı ekle ve bildirim saatini ayarla.
5. Bakım rutini ekle.
6. Veteriner ziyareti ekle (telefon + adres dahil).
7. Profil özetini PDF olarak paylaş.
8. Pati Pasaportu ekranında 2 farklı rota seç.
9. Semptom Günlüğü kaydı oluştur.
10. Uygulamayı kapatıp tekrar aç, verilerin korunduğunu doğrula.

## Kontrol Tablosu

- [ ] Açılışta crash yok
- [ ] Dashboard verileri doğru
- [ ] Aşı kaydı başarılı
- [ ] İlaç kaydı ve log başarılı
- [ ] Bakım rutini başarılı
- [ ] Veteriner kayıt ve aksiyonlar başarılı
- [ ] PDF paylaşımı başarılı
- [ ] Pati Pasaportu checklist görünümü başarılı
- [ ] Semptom kaydı başarılı
- [ ] Uygulama yeniden açılışında veri kaybı yok

## Notlar / Bulgu Alanı

- Bulgu 1:
- Bulgu 2:
- Bulgu 3:

## Sonuç

- [ ] GO (launch için uygun)
- [ ] NO-GO (kritik sorun var)
