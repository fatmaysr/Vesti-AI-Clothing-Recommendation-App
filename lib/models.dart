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

Future<double?> fetchCurrentTemperature() async {
  try {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=40.77&longitude=29.94&current_weather=true',
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