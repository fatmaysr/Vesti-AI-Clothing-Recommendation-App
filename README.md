# 👗 Vesti — AI Destekli Akıllı Dolap Uygulaması

Vesti, kullanıcının kendi gardırobunu dijitalleştirip yapay zeka ile analiz eden, hava durumuna, güne ve ruh haline göre kişiselleştirilmiş kombin önerileri sunan bir mobil uygulamadır. Flutter ile geliştirilmiş, Supabase üzerine kurulu bir backend ve Google Gemini AI ile çalışmaktadır.

Bu proje, sıfırdan mobil uygulama geliştirme öğrenme sürecinin bir parçası olarak, fikir aşamasından çalışan bir Android uygulamasına kadar tek başına geliştirilmiştir.

---

##  Özellikler

###  Dolap Yönetimi
- Kıyafet fotoğrafı çekme/galeriden seçme
- Otomatik fotoğraf sıkıştırma (hız ve depolama optimizasyonu)
- Kıyafet ekleme, silme, listeleme
- **Kategori bazlı filtreleme**: Üst Giyim, Alt Giyim, Dış Giyim, Ev Giyimi, Ayakkabı, Aksesuar

###  Yapay Zeka Entegrasyonu
- **Otomatik kıyafet tanıma**: Yüklenen fotoğraf Google Gemini Vision API ile analiz edilir; kategori, renk, stil ve giysi tipi otomatik olarak çıkarılır
- **AI destekli kombin önerisi**: Dolaptaki kıyafetlerden, aşağıdaki faktörleri dikkate alarak uyumlu bir kombin oluşturulur:
  -  Güncel hava durumu (Open-Meteo API)
  -  Günün durumu (Üniversite / İş / Ev / Spor)
  -  Kullanıcının o anki ruh hali / isteği
  -  Geçmiş beğeni verileri (öğrenen tercih sistemi)

###  Kişiselleştirme
- Her kombine "Beğendim" / "Bana göre değil" geri bildirimi
- Beğenilen renk ve stillerin ağırlıklı puanlama sistemi ile öğrenilmesi
- Sonraki önerilerde bu tercihlerin önceliklendirilmesi
- **Kombinlerim** ekranı: beğenilen kombinlerin kalıcı olarak kaydedilmesi ve görüntülenmesi

###  Kullanıcı Sistemi
- E-posta/şifre ile kayıt ve giriş (Supabase Auth)
- Row Level Security (RLS) ile her kullanıcının yalnızca kendi verilerine erişimi
- Güvenli oturum yönetimi

###  Arayüz
- Özel tasarlanmış mor/lila renk teması
- Yuvarlak köşeli, modern bileşenler
- Yükleniyor durumları, boş durum ekranları, hata yönetimi
- Özel uygulama ikonu

---

##  Kullanılan Teknolojiler

| Katman | Teknoloji |
|---|---|
| Mobil Uygulama | Flutter / Dart |
| Backend & Veritabanı | Supabase (PostgreSQL) |
| Kimlik Doğrulama | Supabase Auth |
| Dosya Depolama | Supabase Storage |
| Sunucu Fonksiyonları | Supabase Edge Functions (Deno/TypeScript) |
| Görsel Analiz & Öneri AI | Google Gemini API (gemini-3.6-flash) |
| Hava Durumu | Open-Meteo API (ücretsiz, key gerektirmez) |
| Yerel Depolama | shared_preferences |

---

##  Mimari

```
┌─────────────────┐
│  Flutter Mobil   │
│   Uygulaması     │
└────────┬─────────┘
         │
         ▼
┌─────────────────────────────────────┐
│           Supabase                   │
│  ┌───────────┐  ┌─────────────────┐ │
│  │PostgreSQL │  │  Auth (JWT)      │ │
│  │ Database  │  │                  │ │
│  └───────────┘  └─────────────────┘ │
│  ┌───────────┐  ┌─────────────────┐ │
│  │  Storage  │  │ Edge Functions   │ │
│  │ (fotoğraf)│  │ (analyze-clothing│ │
│  │           │  │  generate-outfit)│ │
│  └───────────┘  └────────┬─────────┘ │
└────────────────────────────┼─────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Google Gemini   │
                    │       API        │
                    └──────────────────┘
```

Flutter uygulaması, hassas API anahtarlarını (Gemini API key gibi) hiçbir zaman istemci tarafında barındırmaz. Tüm AI çağrıları, anahtarı güvenli şekilde saklayan Supabase Edge Functions üzerinden vekil (proxy) olarak yapılır.

---

##  Proje Yapısı

```
lib/
 ├── main.dart                 # Uygulama girişi, tema tanımı
 ├── supabase_client.dart      # Supabase istemci örneği
 ├── models.dart               # ClothingItem modeli, sabitler, hava durumu servisi
 └── screens/
      ├── auth_screens.dart      # Giriş/Kayıt ekranı, Ana ekran, AuthGate
      ├── wardrobe_screen.dart   # Dolap ekranı, kombin oluşturma mantığı
      └── outfit_screens.dart    # Kombin sonucu, kıyafet ekleme, kaydedilen kombinler
```

**Supabase Edge Functions:**
- `analyze-clothing` — Fotoğrafı Gemini Vision API'ye gönderip kategori/renk/stil/tip bilgisi alır
- `generate-outfit` — Dolap, tercihler, hava durumu, durum ve ruh haline göre kombin önerisi üretir

---

##  Veritabanı Şeması

**clothing_items**
| Sütun | Tip | Açıklama |
|---|---|---|
| id | uuid | Birincil anahtar |
| user_id | uuid | Sahibi (auth.users referansı) |
| name | text | Kıyafet adı |
| image_url | text | Storage'daki fotoğraf linki |
| category | text | AI'ın bulduğu spesifik kategori |
| color | text | Ana renk |
| style | text | Stil (casual/formal/sportif) |
| clothing_type | text | Genel tip (Üst Giyim, Alt Giyim, vb.) |
| created_at | timestamp | Oluşturulma tarihi |

**style_preferences**
| Sütun | Tip | Açıklama |
|---|---|---|
| id | uuid | Birincil anahtar |
| user_id | uuid | Sahibi |
| attribute_type | text | "color" ya da "style" |
| attribute_value | text | Değer (örn. "siyah") |
| score | int | Beğeni puanı (+1/-1 birikimli) |

**saved_outfits**
| Sütun | Tip | Açıklama |
|---|---|---|
| id | uuid | Birincil anahtar |
| user_id | uuid | Sahibi |
| item_ids | uuid[] | Kombindeki kıyafetlerin id listesi |
| reason | text | AI'ın kombin gerekçesi |
| created_at | timestamp | Oluşturulma tarihi |

Tüm tablolarda **Row Level Security (RLS)** aktiftir; her kullanıcı yalnızca `auth.uid() = user_id` eşleşen satırlara erişebilir.

---

##  Kurulum

### Gereksinimler
- Flutter SDK (3.x+)
- Bir Supabase projesi
- Google AI Studio üzerinden ücretsiz bir Gemini API anahtarı

### Adımlar

1. Depoyu klonla:
```bash
git clone https://github.com/KULLANICI_ADIN/vesti.git
cd vesti
```

2. Bağımlılıkları yükle:
```bash
flutter pub get
```

3. `lib/main.dart` içindeki Supabase URL ve anon key'i kendi projenle değiştir.

4. Supabase projende gerekli tabloları ve RLS politikalarını oluştur (yukarıdaki şema referans alınabilir).

5. Supabase Edge Functions'a `analyze-clothing` ve `generate-outfit` fonksiyonlarını deploy et, `GEMINI_API_KEY` secret'ını tanımla.

6. Uygulamayı çalıştır:
```bash
flutter run
```

### Android APK oluşturma
```bash
flutter build apk --release
```
Çıktı: `build/app/outputs/flutter-apk/app-release.apk`

---

##  Geliştirme Yol Haritası

| Aşama | Durum |
|---|---|
| Fikir & Planlama | ✅ |
| Ortam Kurulumu (Flutter/Dart) | ✅ |
| Mobil V0 (temel ekranlar) | ✅ |
| Backend & Veritabanı (Supabase) | ✅ |
| AI Kıyafet Tanıma | ✅ |
| AI Kombin Önerisi | ✅ |
| Kullanıcı Tercih Öğrenme | ✅ |
| Context-Aware AI (hava/durum/mod) | ✅ |
| Kullanıcı Girişi & Güvenlik | ✅ |
| UX/Görsel Cila | ✅ |
| Kod Organizasyonu (çoklu dosya) | ✅ |
| Kullanıcı Testi | 🔶 Devam ediyor |
| Gizlilik Politikası & Hesap Silme | ⏳ Planlanan |
| Production Sertleştirme | ⏳ Planlanan |
| App Store / Play Store Yayını | ⏳ Planlanan |

---

##  Bilinen Sınırlamalar

- Hava durumu şu an sabit bir konuma (İzmit) göre çekilmektedir; il/ilçe bazlı dinamik konum seçimi denenmiş ancak ücretsiz geocoding servislerinin Türkiye'deki kapsama sınırlılığı nedeniyle ertelenmiştir.
- Gemini API'nin ücretsiz katmanı günlük istek limitine sahiptir (model başına ~20 istek/gün); yoğun testte bu sınıra ulaşılabilir.
- Hesap silme ve resmi bir gizlilik politikası henüz eklenmemiştir (mağaza yayını için gereklidir).
- Uygulama arayüzü öncelikli olarak telefon ekran boyutlarına göre tasarlanmıştır; tablet için tam responsive değildir.

---

##  Lisans

Bu proje kişisel bir öğrenme projesi olarak geliştirilmiştir.

---

##  Geliştirici

Bu proje, mobil uygulama geliştirmeyi öğrenme sürecinin bir parçası olarak sıfırdan geliştirilmiştir — Flutter kurulumundan AI entegrasyonuna, backend mimarisinden kullanıcı kimlik doğrulamasına kadar tüm katmanlar dahil.
