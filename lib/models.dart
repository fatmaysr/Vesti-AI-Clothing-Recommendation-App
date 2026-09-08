import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

const Color vestiPrimary = Color(0xFF8B5CF6);
const Color vestiPrimaryLight = Color(0xFFEDE4FF);

class ClothingItem {
  final String id;
  final String name;
  final String? imageUrl;
  final String? category;
  final String? color;
  final String? style;
  final String? clothingType;

  ClothingItem({
    required this.id,
    required this.name,
    this.imageUrl,
    this.category,
    this.color,
    this.style,
    this.clothingType,
  });

  factory ClothingItem.fromMap(Map<String, dynamic> map) {
    return ClothingItem(
      id: map['id'] as String,
      name: map['name'] as String,
      imageUrl: map['image_url'] as String?,
      category: map['category'] as String?,
      color: map['color'] as String?,
      style: map['style'] as String?,
      clothingType: map['clothing_type'] as String?,
    );
  }
}

// Filtre butonlarında kullanacağımız sabit kategori listesi
const List<String> clothingTypes = [
  'Üst Giyim',
  'Alt Giyim',
  'Dış Giyim',
  'Ev Giyimi',
  'Ayakkabı',
  'Aksesuar',
];

Future<double?> fetchCurrentTemperature(double lat, double lon) async {
  try {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['current_weather']['temperature'] as num).toDouble();
    }
  } catch (e) {
    // Hava durumu alınamazsa null döneriz
  }
  return null;
}

class CityOption {
  final String name;
  final double lat;
  final double lon;

  const CityOption(this.name, this.lat, this.lon);
}

const List<CityOption> turkishCities = [
  CityOption('Adana', 37.00, 35.32),
  CityOption('Adıyaman', 37.76, 38.28),
  CityOption('Afyonkarahisar', 38.76, 30.54),
  CityOption('Ağrı', 39.72, 43.05),
  CityOption('Amasya', 40.65, 35.83),
  CityOption('Ankara', 39.93, 32.86),
  CityOption('Antalya', 36.90, 30.71),
  CityOption('Artvin', 41.18, 41.82),
  CityOption('Aydın', 37.85, 27.85),
  CityOption('Balıkesir', 39.65, 27.89),
  CityOption('Bilecik', 40.15, 29.98),
  CityOption('Bingöl', 38.88, 40.50),
  CityOption('Bitlis', 38.40, 42.11),
  CityOption('Bolu', 40.74, 31.60),
  CityOption('Burdur', 37.72, 30.29),
  CityOption('Bursa', 40.19, 29.06),
  CityOption('Çanakkale', 40.15, 26.41),
  CityOption('Çankırı', 40.60, 33.62),
  CityOption('Çorum', 40.55, 34.95),
  CityOption('Denizli', 37.77, 29.09),
  CityOption('Diyarbakır', 37.91, 40.24),
  CityOption('Edirne', 41.68, 26.56),
  CityOption('Elazığ', 38.68, 39.22),
  CityOption('Erzincan', 39.75, 39.49),
  CityOption('Erzurum', 39.90, 41.27),
  CityOption('Eskişehir', 39.78, 30.52),
  CityOption('Gaziantep', 37.07, 37.38),
  CityOption('Giresun', 40.91, 38.39),
  CityOption('Gümüşhane', 40.46, 39.48),
  CityOption('Hakkari', 37.58, 43.74),
  CityOption('Hatay', 36.20, 36.16),
  CityOption('Isparta', 37.76, 30.55),
  CityOption('Mersin', 36.81, 34.64),
  CityOption('İstanbul', 41.01, 28.97),
  CityOption('İzmir', 38.42, 27.14),
  CityOption('Kars', 40.61, 43.10),
  CityOption('Kastamonu', 41.38, 33.78),
  CityOption('Kayseri', 38.73, 35.49),
  CityOption('Kırklareli', 41.73, 27.22),
  CityOption('Kırşehir', 39.15, 34.16),
  CityOption('Kocaeli', 40.85, 29.88),
  CityOption('Konya', 37.87, 32.48),
  CityOption('Kütahya', 39.42, 29.98),
  CityOption('Malatya', 38.36, 38.31),
  CityOption('Manisa', 38.61, 27.43),
  CityOption('Kahramanmaraş', 37.57, 36.94),
  CityOption('Mardin', 37.31, 40.74),
  CityOption('Muğla', 37.22, 28.36),
  CityOption('Muş', 38.74, 41.50),
  CityOption('Nevşehir', 38.62, 34.71),
  CityOption('Niğde', 37.97, 34.69),
  CityOption('Ordu', 40.98, 37.88),
  CityOption('Rize', 41.02, 40.52),
  CityOption('Sakarya', 40.78, 30.40),
  CityOption('Samsun', 41.29, 36.33),
  CityOption('Siirt', 37.93, 41.94),
  CityOption('Sinop', 42.03, 35.15),
  CityOption('Sivas', 39.75, 37.02),
  CityOption('Tekirdağ', 40.98, 27.51),
  CityOption('Tokat', 40.32, 36.55),
  CityOption('Trabzon', 41.00, 39.72),
  CityOption('Tunceli', 39.11, 39.55),
  CityOption('Şanlıurfa', 37.16, 38.79),
  CityOption('Uşak', 38.68, 29.41),
  CityOption('Van', 38.49, 43.38),
  CityOption('Yozgat', 39.82, 34.80),
  CityOption('Zonguldak', 41.46, 31.79),
  CityOption('Aksaray', 38.37, 34.03),
  CityOption('Bayburt', 40.26, 40.22),
  CityOption('Karaman', 37.18, 33.22),
  CityOption('Kırıkkale', 39.85, 33.51),
  CityOption('Batman', 37.88, 41.13),
  CityOption('Şırnak', 37.52, 42.46),
  CityOption('Bartın', 41.63, 32.34),
  CityOption('Ardahan', 41.11, 42.70),
  CityOption('Iğdır', 39.92, 44.05),
  CityOption('Yalova', 40.65, 29.28),
  CityOption('Karabük', 41.20, 32.63),
  CityOption('Kilis', 36.72, 37.12),
  CityOption('Osmaniye', 37.07, 36.25),
  CityOption('Düzce', 40.84, 31.16),
];
