import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

// Open-Meteo'dan hava durumunu çeken basit fonksiyon (İzmit koordinatları)
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
    // Hava durumu alınamazsa null döneriz, uygulama yine de çalışır
  }
  return null;
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
  bool isGeneratingOutfit = false;

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

  // Kullanıcıya "bugün neredesin" diye soran küçük bir seçim penceresi
  Future<String?> _askContext() async {
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Bugün neredesin?'),
        children: [
          for (final option in ['Üniversite', 'İş', 'Ev', 'Spor'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, option),
              child: Text(option),
            ),
        ],
      ),
    );
  }

  Future<void> _generateOutfit() async {
    if (clothes.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kombin oluşturmak için en az 2 kıyafet ekle.'),
        ),
      );
      return;
    }

    final selectedContext = await _askContext();
    if (selectedContext == null) return; // kullanıcı vazgeçti

    setState(() {
      isGeneratingOutfit = true;
    });

    try {
      // Hava durumunu çek
      final temperature = await fetchCurrentTemperature();

      // Geçmiş tercihleri (style_preferences) tablosundan çekelim
      final prefsData = await supabase
          .from('style_preferences')
          .select()
          .order('score', ascending: false)
          .limit(5);
      final preferencesList = prefsData as List;

      final itemsPayload = clothes
          .map(
            (item) => {
              'id': item.id,
              'name': item.name,
              'category': item.category,
              'color': item.color,
              'style': item.style,
            },
          )
          .toList();

      // Edge function'a kıyafetleri, tercihleri, hava durumunu ve durumu gönderelim
      final response = await supabase.functions.invoke(
        'generate-outfit',
        body: {
          'items': itemsPayload,
          'preferences': preferencesList,
          'weather': temperature,
          'context': selectedContext,
        },
      );

      final result = response.data as Map<String, dynamic>;
      final List<dynamic> selectedIds = result['itemIds'] ?? [];
      final String reason = result['reason'] ?? '';

      final selectedItems = clothes
          .where((item) => selectedIds.contains(item.id))
          .toList();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OutfitScreen(items: selectedItems, reason: reason),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Kombin oluşturulamadı: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingOutfit = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dolabım')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isGeneratingOutfit ? null : _generateOutfit,
                      icon: isGeneratingOutfit
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        isGeneratingOutfit
                            ? 'Kombin hazırlanıyor...'
                            : 'Bugünün Kombini',
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: clothes.isEmpty
                      ? const Center(
                          child: Text(
                            'Henüz kıyafet yok.',
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          itemCount: clothes.length,
                          itemBuilder: (context, index) {
                            final item = clothes[index];
                            final subtitleParts = [
                              if (item.category != null) item.category,
                              if (item.color != null) item.color,
                              if (item.style != null) item.style,
                            ];
                            final subtitle = subtitleParts.join(' • ');

                            return ListTile(
                              leading: item.imageUrl != null
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        item.imageUrl!,
                                      ),
                                    )
                                  : const Icon(Icons.checkroom),
                              title: Text(item.name),
                              subtitle: subtitle.isNotEmpty
                                  ? Text(subtitle)
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () => _confirmDelete(index),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToAddClothing,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// AI'ın önerdiği kombini gösteriyor ve puanlama butonlarını içeriyor
class OutfitScreen extends StatefulWidget {
  final List<ClothingItem> items;
  final String reason;

  const OutfitScreen({super.key, required this.items, required this.reason});

  @override
  State<OutfitScreen> createState() => _OutfitScreenState();
}

class _OutfitScreenState extends State<OutfitScreen> {
  bool hasVoted = false;

  Future<void> _rateOutfit(int scoreChange) async {
    if (hasVoted) return;

    try {
      for (var item in widget.items) {
        if (item.color != null && item.color!.isNotEmpty) {
          await _updatePreference('color', item.color!, scoreChange);
        }
        if (item.style != null && item.style!.isNotEmpty) {
          await _updatePreference('style', item.style!, scoreChange);
        }
      }

      setState(() {
        hasVoted = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              scoreChange > 0
                  ? 'Geri bildirimin kaydedildi! Sevdiklerin önceliklendirilecek.'
                  : 'Geri bildirimin kaydedildi.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Oy kaydedilirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _updatePreference(String type, String value, int change) async {
    final existing = await supabase
        .from('style_preferences')
        .select()
        .eq('attribute_type', type)
        .eq('attribute_value', value)
        .maybeSingle();

    if (existing != null) {
      final int currentScore = existing['score'] as int;
      await supabase
          .from('style_preferences')
          .update({'score': currentScore + change})
          .eq('id', existing['id']);
    } else {
      await supabase.from('style_preferences').insert({
        'attribute_type': type,
        'attribute_value': value,
        'score': change,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Önerilen Kombin')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.reason.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(child: Text(widget.reason)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: widget.items.isEmpty
                  ? const Center(child: Text('AI bir kombin bulamadı.'))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                      itemCount: widget.items.length,
                      itemBuilder: (context, index) {
                        final item = widget.items[index];
                        return Column(
                          children: [
                            Expanded(
                              child: item.imageUrl != null
                                  ? Image.network(
                                      item.imageUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.checkroom,
                                        size: 40,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 4),
                            Text(item.name),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: hasVoted ? null : () => _rateOutfit(-1),
                  icon: const Icon(Icons.thumb_down, color: Colors.red),
                  label: const Text('Bana göre değil'),
                ),
                ElevatedButton.icon(
                  onPressed: hasVoted ? null : () => _rateOutfit(1),
                  icon: const Icon(Icons.favorite, color: Colors.pink),
                  label: const Text('Beğendim'),
                ),
              ],
            ),
          ],
        ),
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
        aiResult = null;
      }
    }

    setState(() {
      statusText = 'Kaydediliyor...';
    });

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
