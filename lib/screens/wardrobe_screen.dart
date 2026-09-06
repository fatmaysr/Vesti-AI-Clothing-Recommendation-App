import 'package:flutter/material.dart';
import '../supabase_client.dart';
import '../models.dart';
import 'outfit_screens.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  List<ClothingItem> clothes = [];
  bool isLoading = true;
  bool isGeneratingOutfit = false;
  String? selectedFilter; // null = Tümü

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

  List<ClothingItem> get filteredClothes {
    if (selectedFilter == null) return clothes;
    return clothes.where((item) => item.clothingType == selectedFilter).toList();
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            selectedFilter = value;
          });
        },
        selectedColor: vestiPrimaryLight,
        checkmarkColor: vestiPrimary,
        labelStyle: TextStyle(
          color: isSelected ? vestiPrimary : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? vestiPrimary : Colors.grey[300]!),
        ),
      ),
    );
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

  Future<void> _confirmDelete(ClothingItem item) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kıyafeti sil'),
        content: Text('${item.name} silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () async {
              await supabase.from('clothing_items').delete().eq('id', item.id);
              Navigator.pop(context);
              _loadClothes();
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<String?> _askContext() async {
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  Future<String?> _askMood() async {
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Bugün nasıl hissediyorsun?'),
        children: [
          for (final option in [
            'Enerjik ve Renkli Görünmek İstiyorum',
            'Sade ve Şık Olsun',
            'Rahat ve Gündelik Olsun',
            'Kendimi Şımartmak İstiyorum, İddialı Bir Şey',
          ])
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
        const SnackBar(content: Text('Kombin oluşturmak için en az 2 kıyafet ekle.')),
      );
      return;
    }

    final selectedContext = await _askContext();
    if (selectedContext == null) return;

    final selectedMood = await _askMood();
    if (selectedMood == null) return;

    setState(() {
      isGeneratingOutfit = true;
    });

    try {
      final temperature = await fetchCurrentTemperature();

      final prefsData = await supabase
          .from('style_preferences')
          .select()
          .order('score', ascending: false)
          .limit(5);
      final preferencesList = prefsData as List;

      final itemsPayload = clothes
          .map((item) => {
                'id': item.id,
                'name': item.name,
                'category': item.category,
                'color': item.color,
                'style': item.style,
              })
          .toList();

      final response = await supabase.functions.invoke(
        'generate-outfit',
        body: {
          'items': itemsPayload,
          'preferences': preferencesList,
          'weather': temperature,
          'context': selectedContext,
          'mood': selectedMood,
        },
      );

      final result = response.data as Map<String, dynamic>;
      final List<dynamic> selectedIds = result['itemIds'] ?? [];
      final String reason = result['reason'] ?? '';

      final selectedItems = clothes.where((item) => selectedIds.contains(item.id)).toList();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OutfitScreen(items: selectedItems, reason: reason)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kombin oluşturulamadı: $e')));
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
      appBar: AppBar(
        title: const Text('Dolabım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Kombinlerim',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SavedOutfitsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: vestiPrimary))
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(isGeneratingOutfit ? 'Kombin hazırlanıyor...' : 'Bugünün Kombini'),
                    ),
                  ),
                ),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _buildFilterChip('Tümü', null),
                      for (final type in clothingTypes) _buildFilterChip(type, type),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filteredClothes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.checkroom_outlined, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('Henüz kıyafet yok.', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                              const SizedBox(height: 4),
                              Text('Aşağıdaki + butonuyla ekleyebilirsin.',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredClothes.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = filteredClothes[index];
                            final subtitleParts = [
                              if (item.category != null) item.category,
                              if (item.color != null) item.color,
                              if (item.style != null) item.style,
                            ];
                            final subtitle = subtitleParts.join(' • ');

                            return Container(
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                leading: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: vestiPrimaryLight,
                                  backgroundImage: item.imageUrl != null ? NetworkImage(item.imageUrl!) : null,
                                  child: item.imageUrl == null
                                      ? const Icon(Icons.checkroom, color: vestiPrimary)
                                      : null,
                                ),
                                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                                trailing: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.redAccent),
                                  onPressed: () => _confirmDelete(item),
                                ),
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