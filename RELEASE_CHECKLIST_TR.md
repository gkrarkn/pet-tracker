# Pet Tracker Release Checklist

Bu liste launch öncesi son kontrol için hazırlandı. Her maddeyi tek tek işaretleyip ancak ondan sonra build alın.

## 1. Kritik Ürün Kontrolleri

- [ ] İlk açılışta uygulama açılıyor, boş ekran veya crash yok.
- [ ] Yeni evcil hayvan ekleme, düzenleme ve silme akışları çalışıyor.
- [ ] Dashboard verileri doğru yükleniyor.
- [ ] Evcil Hayvanlarım, Bugün / Yakında Yapılacaklar ve Akıllı Özetler bölümleri görünüyor.
- [ ] Aşı Takibi ekranında yeni aşı ekleme, düzenleme ve silme sorunsuz.
- [ ] İlaç Takibi ekranında saat seçimi, alındı / alınmadı ve log kaydı çalışıyor.
- [ ] Bakım Rutinleri ekranında görev ekleme, tamamlama ve tekrar planlama doğru.
- [ ] Veteriner Ziyaretleri ekranında kategori, telefon, adres ve aksiyonlar görünüyor.
- [ ] Semptom Günlüğü ekranında hızlı kayıt ve rapor akışı çalışıyor.
- [ ] Bakıcı Erişimi ekranında davet kodu ve işlem geçmişi görünüyor.
- [ ] Pati Pasaportu ekranında tüm rota / havayolu presetleri listeleniyor.
- [ ] Belgeler ekranında belge ekleme, görüntüleme ve silme akışı stabil.

## 2. Bildirim ve Hatırlatma Kontrolleri

- [ ] Aşı bildirimleri doğru tarih ve saatte geliyor.
- [ ] İlaç bildirimleri doğru tarih ve saatte geliyor.
- [ ] Bakım rutini bildirimleri doğru tarih ve saatte geliyor.
- [ ] Bildirim üstünden `Tamamlandı` aksiyonu çalışıyor.
- [ ] Bildirim üstünden `Ertele 10 dk` aksiyonu çalışıyor.
- [ ] Bildirim üstünden `Bugün atla` aksiyonu beklenen şekilde kayda geçiyor.
- [ ] Uygulama kapalıyken de bildirimler gelmeye devam ediyor.
- [ ] iOS bildirim izinleri ilk açılışta veya uygun anda doğru isteniyor.

## 3. Veri ve Mantık Kontrolleri

- [ ] Yaklaşan / geciken aşı mantığı doğru etiketleniyor.
- [ ] Kalan gün hesapları doğru.
- [ ] Kilo grafiğinde tarih ekseni okunaklı ve tekrar etmiyor.
- [ ] Dashboard görevleri tekrarlı veya eksik görünmüyor.
- [ ] Silinen kayıtlarda confirm veya undo mekanizması çalışıyor.
- [ ] Boş state metinleri yönlendirici ve anlaşılır.
- [ ] Türkçe karakterler tüm yeni ekranlarda doğru görünüyor.

## 4. Paylaşım ve PDF Kontrolleri

- [ ] Profil özetini metin olarak paylaşma çalışıyor.
- [ ] PDF oluşturma crash vermeden tamamlanıyor.
- [ ] Veteriner raporu PDF tasarımı tek sayfada düzgün görünüyor.
- [ ] Veteriner telefon ve adres bilgileri PDF'e yansıyor.
- [ ] `Takvime Ekle` aksiyonu `.ics` dosyasını doğru üretiyor.
- [ ] `Kopyala`, `Ara`, `Yol Tarifi Al` aksiyonları beklenen şekilde çalışıyor.

## 5. Seyahat Modu Kontrolleri

- [ ] Pati Pasaportu ekranında resmi uyarı kartı görünüyor.
- [ ] Aşağıdaki rota ve havayolu seçenekleri listeleniyor:
  - [ ] Yunanistan
  - [ ] Almanya
  - [ ] İngiltere
  - [ ] ABD
  - [ ] Kanada
  - [ ] Fransa
  - [ ] Hollanda
  - [ ] İtalya
  - [ ] İspanya
  - [ ] THY ile Uçuş
  - [ ] Pegasus ile Uçuş
  - [ ] AJet ile Uçuş
  - [ ] Lufthansa ile Uçuş
- [ ] Her seçimde uygun bilgi notu değişiyor.
- [ ] Checklist verileri kullanıcıyı yanıltmayacak şekilde rehber tonunda.
- [ ] Resmi kural doğrulaması gerektiğini anlatan metin görünür durumda.

## 6. Kamera ve Tarama Notu

- [ ] `Aşı Karnesini Tara` ekranı açılıyor.
- [ ] Simulator ortamında kamera yoksa kullanıcıya anlamlı uyarı gösteriliyor.
- [ ] Galeriden seçme akışı çalışıyor.
- [ ] Manuel metin yapıştırma ile parse akışı çalışıyor.
- [ ] Kamera ile otomatik OCR özelliği launch sonrası yol haritasında olarak not edildi.

## 7. UI / UX Son Kontroller

- [ ] App icon son seçilen logo ile güncel.
- [ ] Splash veya açılış deneyimi kabul edilebilir.
- [ ] Metin taşmaları, overflow ve kırık layout yok.
- [ ] Karanlık / açık sistem farklarında kritik okunabilirlik sorunu yok.
- [ ] iPhone 17 simulator ve en az bir küçük ekran test edildi.
- [ ] Bottom sheet aksiyonları tutarlı görünüyor.

## 8. App Store / Launch Hazırlığı

- [ ] Uygulama adı, alt başlık ve açıklama hazır.
- [ ] App Store ekran görüntüleri hazır.
- [ ] Gizlilik metni hazır.
- [ ] Destek e-postası veya iletişim sayfası hazır.
- [ ] Bildirim kullanım amacı açık ve düzgün anlatıldı.
- [ ] Kamera / galeri / bildirim izin metinleri kontrol edildi.

## 9. Teknik Son Kontroller

- [ ] `flutter analyze` temiz.
- [ ] iOS simulator build alınıyor.
- [ ] Gerekirse fiziksel iPhone üzerinde test yapıldı.
- [ ] `pubspec.yaml` içinde artık kullanılmayan bağımlılık kalmadı.
- [ ] Crash'e sebep olabilecek debug kodları temizlendi.
- [ ] Örnek / test verisi launch build'inde kullanıcıyı şaşırtmayacak durumda.

## 10. Launch Sonrası V2'ye Bırakılanlar

- [ ] Kamera ile otomatik OCR'dan aşı tarihi okuma
- [ ] Resmi kaynaklardan canlı ülke / havayolu kural güncelleme
- [ ] Cloud tabanlı bakıcı erişimi ve gerçek zamanlı bildirimler
- [ ] Daha gelişmiş semptom analizi ve veteriner hazırlık raporu
- [ ] Premium analizler ve daha derin sağlık trendleri

## Önerilen Son Test Akışı

1. Temiz kurulum yap.
2. Bir evcil hayvan oluştur.
3. Aşı, ilaç, bakım, kilo ve veteriner kaydı ekle.
4. Bildirimleri test et.
5. PDF paylaşımı test et.
6. Pati Pasaportu ve Semptom Günlüğü ekranlarını test et.
7. Uygulamayı kapatıp tekrar aç.
8. Son olarak App Store ekran görüntülerini al.
