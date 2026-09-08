# 👗 Vesti — AI Destekli Akıllı Dolap

Vesti, kullanıcıların gardıroplarını dijitalleştirerek yapay zeka ile analiz eden ve kişiselleştirilmiş kombin önerileri sunan bir mobil uygulamadır.

Kullanıcının kıyafetleri; **hava durumu, günün durumu, ruh hali ve geçmiş tercihleri** dikkate alınarak analiz edilir ve uygun kombinler oluşturulur.

Proje, fikir aşamasından çalışan bir Android uygulamasına kadar **tek başına geliştirilmiş bir öğrenme ve ürün geliştirme projesidir.**

---

##  Özellikler

###  Akıllı Dolap

* Kameradan veya galeriden kıyafet ekleme
* Otomatik fotoğraf sıkıştırma
* Kıyafet ekleme, silme ve listeleme
* Kategori bazlı filtreleme
* 81 il üzerinden şehir seçimi ve hava durumu takibi

###  Yapay Zeka

* **Otomatik kıyafet analizi**

  * Kategori
  * Renk
  * Stil
  * Giysi türü
* **AI destekli kombin önerileri**

  *  Güncel hava durumu
  *  Günün durumu (Üniversite / İş / Ev / Spor)
  *  Ruh hali / istek
  *  Kullanıcının geçmiş tercihleri

###  Kişiselleştirme

* Kombinlere "Beğendim" / "Bana göre değil" geri bildirimi
* Beğenilen renk ve stillerin puanlanması
* Geçmiş tercihlere göre önerilerin kişiselleştirilmesi
* Beğenilen kombinleri **Kombinlerim** ekranında kaydetme

###  Kullanıcı & Güvenlik

* Supabase Auth ile e-posta/şifre ile kayıt ve giriş
* Row Level Security (RLS)
* Kullanıcı verilerinin birbirinden izole edilmesi
* Gemini API anahtarının istemci tarafında tutulmaması

---

## 🛠️ Teknolojiler

| Alan               | Teknoloji               |
| ------------------ | ----------------------- |
| Mobil              | Flutter / Dart          |
| Backend & Database | Supabase / PostgreSQL   |
| Authentication     | Supabase Auth           |
| Storage            | Supabase Storage        |
| Server Functions   | Supabase Edge Functions |
| AI                 | Google Gemini API       |
| Hava Durumu        | Open-Meteo API          |
| Yerel Depolama     | shared_preferences      |

---

##  Mimari

```text
┌─────────────────────┐
│   Flutter Mobile    │
│      App            │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────────────┐
│          Supabase           │
│                             │
│ PostgreSQL  │ Auth │Storage │
│             │      │        │
│       Edge Functions         │
└──────────────┬──────────────┘
               │
               ▼
      ┌─────────────────┐
      │  Google Gemini  │
      │      API        │
      └─────────────────┘
```

AI işlemleri Supabase Edge Functions üzerinden gerçekleştirilir. Gemini API anahtarı istemci tarafında tutulmaz.

---

##  Proje Yapısı

```text
lib/
 ├── main.dart
 ├── supabase_client.dart
 ├── models.dart
 └── screens/
      ├── auth_screens.dart
      ├── wardrobe_screen.dart
      └── outfit_screens.dart
```

### Supabase Edge Functions

* `analyze-clothing` — Kıyafet fotoğrafını analiz eder.
* `generate-outfit` — Dolap, hava durumu ve kullanıcı tercihlerini dikkate alarak kombin önerir.

---

##  Veritabanı

Vesti'nin temel verileri üç ana tabloda tutulur:

* `clothing_items` — Kullanıcı kıyafetleri ve AI analiz sonuçları
* `style_preferences` — Kullanıcının renk ve stil tercihleri
* `saved_outfits` — Kaydedilen kombinler

Tüm tablolarda **Row Level Security (RLS)** aktiftir.

---

##  Kurulum

### Gereksinimler

* Flutter SDK 3.x+
* Supabase projesi
* Gemini API anahtarı

### Kurulum

```bash
git clone https://github.com/fatmaysr/Vesti-AI-Clothing-Recommendation-App.git
cd Vesti-AI-Clothing-Recommendation-App

flutter pub get
flutter run
```

Supabase tarafında gerekli tablolar, RLS politikaları ve Edge Functions yapılandırılmalıdır.

Gemini API anahtarı **Supabase Edge Functions secret** olarak tanımlanmalıdır.

###  APK

Hazır Android APK'yı indirip doğrudan deneyebilirsiniz:

**[Vesti v1.0.0 — Android APK](https://github.com/fatmaysr/Vesti-AI-Clothing-Recommendation-App/releases/download/v1.0.0/app-release.apk)**

Kendi APK'nızı oluşturmak için:

```bash
flutter build apk --release
```

---

##  Bilinen Sınırlamalar

* Şehir seçimi şu anda Türkiye'nin 81 ili ile sınırlıdır; ilçe/mahalle bazlı konum seçimi bulunmamaktadır.
* Gemini API'nin ücretsiz kullanımında günlük istek limitleri bulunmaktadır.
* Hesap silme ve resmi gizlilik politikası henüz eklenmemiştir.
* Arayüz öncelikli olarak telefon ekranlarına göre tasarlanmıştır; tablet desteği sınırlıdır.

---

## Lisans

Bu proje kişisel bir öğrenme ve geliştirme projesidir.

---

## Not

Vesti; Flutter ile mobil uygulama geliştirme, Supabase ile backend ve veritabanı yönetimi, kullanıcı kimlik doğrulama, API entegrasyonu ve yapay zeka kullanımını tek bir gerçek dünya projesinde birleştirmek amacıyla geliştirilmiştir.
