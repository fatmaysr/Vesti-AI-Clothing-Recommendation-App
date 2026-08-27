import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xmkozokvhqpbghieobxn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhta296b2t2aHFwYmdoaWVvYnhuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc4NTI5NjAsImV4cCI6MjEwMzQyODk2MH0.5sAG1hlAqmMM3vNFiDvXuD5KFq7-v2PpRhfwe7lq0ZE',
  );

  runApp(const VestiApp());
}

final supabase = Supabase.instance.client;

class ClothingItem {
  final String id;
  final String name;
  final String? imageUrl;
  final String? category;
  final String? color;
  final String? style;

  ClothingItem({
    required this.id,
    required this.name,
    this.imageUrl,
    this.category,
    this.color,
    this.style,
  });

  factory ClothingItem.fromMap(Map<String, dynamic> map) {
    return ClothingItem(
      id: map['id'] as String,
      name: map['name'] as String,
      imageUrl: map['image_url'] as String?,
      category: map['category'] as String?,
      color: map['color'] as String?,
      style: map['style'] as String?,
    );
  }
}

class VestiApp extends StatelessWidget {
  const VestiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vesti',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vesti')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Dolabına hoş geldin!', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WardrobeScreen(),
                  ),
                );
              },
              child: const Text('Dolabım'),
            ),
          ],
        ),
      ),
    );
  }
}

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  List<ClothingItem> clothes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClothes();
  }

  Future<void> _loadClothes() async {
    final data = await supabase
        .from('clothing_items')
        .select()
        .order('created_at', ascending: false);

    setState(() {
      clothes = (data as List).map((row) => ClothingItem.fromMap(row)).toList();
      isLoading = false;
    });
  }

  Future<void> _goToAddClothing() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddClothingScreen()),
    );

    if (added == true) {
      _loadClothes();
    }
  }

  Future<void> _confirmDelete(int index) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kıyafeti sil'),
        content: Text('${clothes[index].name} silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () async {
              await supabase
                  .from('clothing_items')
                  .delete()
                  .eq('id', clothes[index].id);
              Navigator.pop(context);
              _loadClothes();
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dolabım')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : clothes.isEmpty
          ? const Center(
              child: Text('Henüz kıyafet yok.', style: TextStyle(fontSize: 18)),
            )
          : ListView.builder(
              itemCount: clothes.length,
              itemBuilder: (context, index) {
                final item = clothes[index];

                // AI bilgileri varsa alt yazı olarak göster
                final subtitleParts = [
                  if (item.category != null) item.category,
                  if (item.color != null) item.color,
                  if (item.style != null) item.style,
                ];
                final subtitle = subtitleParts.join(' • ');

                return ListTile(
                  leading: item.imageUrl != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(item.imageUrl!),
                        )
                      : const Icon(Icons.checkroom),
                  title: Text(item.name),
                  subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _confirmDelete(index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToAddClothing,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddClothingScreen extends StatefulWidget {
  const AddClothingScreen({super.key});

  @override
  State<AddClothingScreen> createState() => _AddClothingScreenState();
}

class _AddClothingScreenState extends State<AddClothingScreen> {
  final TextEditingController _controller = TextEditingController();
  Uint8List? _pickedImageBytes;
  bool isSaving = false;
  String statusText = '';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
      });
    }
  }

  Future<void> _saveClothing() async {
    setState(() {
      isSaving = true;
      statusText = 'Fotoğraf yükleniyor...';
    });

    String? imageUrl;
    Map<String, dynamic>? aiResult;

    if (_pickedImageBytes != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage
          .from('clothing-images')
          .uploadBinary(fileName, _pickedImageBytes!);

      imageUrl = supabase.storage
          .from('clothing-images')
          .getPublicUrl(fileName);

      // Fotoğraf yüklendi, şimdi AI'a analiz ettirelim
      setState(() {
        statusText = 'AI kıyafeti inceliyor...';
      });

      try {
        final response = await supabase.functions.invoke(
          'analyze-clothing',
          body: {'imageUrl': imageUrl},
        );

        aiResult = response.data as Map<String, dynamic>;
      } catch (e) {
        // AI analizi başarısız olsa bile kıyafeti kaydetmeye devam edelim
        aiResult = null;
      }
    }

    setState(() {
      statusText = 'Kaydediliyor...';
    });

    // İsim boşsa, AI'ın bulduğu kategoriyi isim olarak kullan
    final finalName = _controller.text.isNotEmpty
        ? _controller.text
        : (aiResult?['category'] as String? ?? 'İsimsiz');

    await supabase.from('clothing_items').insert({
      'name': finalName,
      'image_url': imageUrl,
      'category': aiResult?['category'],
      'color': aiResult?['color'],
      'style': aiResult?['style'],
    });

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kıyafet Ekle')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
                child: _pickedImageBytes != null
                    ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                    : const Center(child: Text('Fotoğraf seçmek için dokun')),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Kıyafet adı (boş bırakırsan AI bulur)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSaving ? null : _saveClothing,
              child: isSaving
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(statusText),
                      ],
                    )
                  : const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}
