import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../supabase_client.dart';
import '../models.dart';

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

      if (scoreChange > 0) {
        await supabase.from('saved_outfits').insert({
          'item_ids': widget.items.map((item) => item.id).toList(),
          'reason': widget.reason,
        });
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Oy kaydedilirken hata oluştu: $e')));
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
      await supabase.from('style_preferences').update({'score': currentScore + change}).eq('id', existing['id']);
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: vestiPrimaryLight, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: vestiPrimary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(widget.reason, style: const TextStyle(color: Color(0xFF4C1D95)))),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: widget.items.isEmpty
                  ? const Center(child: Text('AI bir kombin bulamadı.'))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: widget.items.length,
                      itemBuilder: (context, index) {
                        final item = widget.items[index];
                        return Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              Expanded(
                                child: item.imageUrl != null
                                    ? Image.network(item.imageUrl!, fit: BoxFit.cover, width: double.infinity)
                                    : Container(
                                        color: vestiPrimaryLight,
                                        child: const Icon(Icons.checkroom, size: 40, color: vestiPrimary),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: hasVoted ? null : () => _rateOutfit(-1),
                  icon: const Icon(Icons.thumb_down, color: Colors.redAccent),
                  label: const Text('Bana göre değil'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: hasVoted ? null : () => _rateOutfit(1),
                  icon: const Icon(Icons.favorite, color: Colors.white),
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
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 75,
    );

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

      await supabase.storage.from('clothing-images').uploadBinary(fileName, _pickedImageBytes!);
      imageUrl = supabase.storage.from('clothing-images').getPublicUrl(fileName);

      setState(() {
        statusText = 'AI kıyafeti inceliyor...';
      });

      try {
        final response = await supabase.functions.invoke('analyze-clothing', body: {'imageUrl': imageUrl});
        aiResult = response.data as Map<String, dynamic>;
      } catch (e) {
        aiResult = null;
      }
    }

    setState(() {
      statusText = 'Kaydediliyor...';
    });

    final finalName = _controller.text.isNotEmpty ? _controller.text : (aiResult?['category'] as String? ?? 'İsimsiz');

    await supabase.from('clothing_items').insert({
      'name': finalName,
      'image_url': imageUrl,
      'category': aiResult?['category'],
      'color': aiResult?['color'],
      'style': aiResult?['style'],
      'clothing_type': aiResult?['clothing_type'],
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
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(color: vestiPrimaryLight, borderRadius: BorderRadius.circular(20)),
                clipBehavior: Clip.antiAlias,
                child: _pickedImageBytes != null
                    ? Image.memory(
                        _pickedImageBytes!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              _pickedImageBytes = null;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Bu fotoğraf açılamadı (desteklenmeyen format olabilir). Lütfen JPG/PNG bir fotoğraf dene.',
                                ),
                              ),
                            );
                          });
                          return const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40));
                        },
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_outlined, size: 40, color: vestiPrimary),
                            const SizedBox(height: 8),
                            Text('Fotoğraf seçmek için dokun', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Kıyafet adı (boş bırakırsan AI bulur)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _saveClothing,
                child: isSaving
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Text(statusText),
                        ],
                      )
                    : const Text('Ekle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Kullanıcının beğenip kaydettiği kombinlerin listesi
class SavedOutfitsScreen extends StatefulWidget {
  const SavedOutfitsScreen({super.key});

  @override
  State<SavedOutfitsScreen> createState() => _SavedOutfitsScreenState();
}

class _SavedOutfitsScreenState extends State<SavedOutfitsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> savedOutfits = [];
  Map<String, ClothingItem> itemsById = {};

  @override
  void initState() {
    super.initState();
    _loadSavedOutfits();
  }

  Future<void> _loadSavedOutfits() async {
    final outfitsData = await supabase
        .from('saved_outfits')
        .select()
        .order('created_at', ascending: false);

    final outfits = List<Map<String, dynamic>>.from(outfitsData);

    final allItemIds = <String>{};
    for (final outfit in outfits) {
      final ids = List<String>.from(outfit['item_ids'] ?? []);
      allItemIds.addAll(ids);
    }

    Map<String, ClothingItem> itemsMap = {};
    if (allItemIds.isNotEmpty) {
      final itemsData = await supabase
          .from('clothing_items')
          .select()
          .filter('id', 'in', '(${allItemIds.join(',')})');

      for (final row in itemsData as List) {
        final item = ClothingItem.fromMap(row);
        itemsMap[item.id] = item;
      }
    }

    setState(() {
      savedOutfits = outfits;
      itemsById = itemsMap;
      isLoading = false;
    });
  }

  Future<void> _deleteSavedOutfit(String id) async {
    await supabase.from('saved_outfits').delete().eq('id', id);
    _loadSavedOutfits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kombinlerim')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: vestiPrimary))
          : savedOutfits.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('Henüz kaydedilmiş kombin yok.',
                          style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                      const SizedBox(height: 4),
                      Text('Beğendiğin kombinler burada birikecek.',
                          style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: savedOutfits.length,
                  itemBuilder: (context, index) {
                    final outfit = savedOutfits[index];
                    final itemIds = List<String>.from(outfit['item_ids'] ?? []);
                    final items = itemIds
                        .map((id) => itemsById[id])
                        .whereType<ClothingItem>()
                        .toList();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  outfit['reason'] ?? '',
                                  style: const TextStyle(color: Color(0xFF4C1D95)),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () => _deleteSavedOutfit(outfit['id']),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 90,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: items.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 8),
                              itemBuilder: (context, i) {
                                final item = items[i];
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: item.imageUrl != null
                                      ? Image.network(item.imageUrl!, width: 90, height: 90, fit: BoxFit.cover)
                                      : Container(
                                          width: 90,
                                          height: 90,
                                          color: vestiPrimaryLight,
                                          child: const Icon(Icons.checkroom, color: vestiPrimary),
                                        ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}