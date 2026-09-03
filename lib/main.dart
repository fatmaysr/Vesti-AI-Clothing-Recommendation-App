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

class VestiApp extends StatelessWidget {
  const VestiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vesti',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: vestiPrimary,
          primary: vestiPrimary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF8FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: vestiPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: vestiPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: vestiPrimary,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: vestiPrimary, width: 2),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        listTileTheme: ListTileThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tileColor: Colors.white,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// Uygulamanın "kapısı": kullanıcı giriş yapmışsa dolabı, yapmamışsa
// giriş ekranını gösterir. Giriş durumu değiştikçe otomatik geçiş yapar.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;

        if (session != null) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isSignUpMode = false;
  bool isLoading = false;
  String? errorMessage;

  Future<void> _submit() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (isSignUpMode) {
        await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      // Başarılıysa AuthGate otomatik olarak HomeScreen'e geçirecek
    } on AuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Bir şeyler ters gitti: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: vestiPrimaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.checkroom, size: 56, color: vestiPrimary),
              ),
              const SizedBox(height: 20),
              const Text(
                'Vesti',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: vestiPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                isSignUpMode ? 'Yeni bir hesap oluştur' : 'Hesabına giriş yap',
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-posta'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Şifre (en az 6 karakter)'),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isSignUpMode ? 'Kayıt Ol' : 'Giriş Yap'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    isSignUpMode = !isSignUpMode;
                    errorMessage = null;
                  });
                },
                child: Text(
                  isSignUpMode
                      ? 'Zaten hesabın var mı? Giriş yap'
                      : 'Hesabın yok mu? Kayıt ol',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: vestiPrimaryLight, shape: BoxShape.circle),
                child: const Icon(Icons.checkroom, size: 64, color: vestiPrimary),
              ),
              const SizedBox(height: 24),
              const Text('Vesti', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: vestiPrimary)),
              const SizedBox(height: 8),
              Text('Dolabına hoş geldin!', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WardrobeScreen()),
                    );
                  },
                  icon: const Icon(Icons.door_sliding_outlined),
                  label: const Text('Dolabımı Aç'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () async {
                  await supabase.auth.signOut();
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Çıkış Yap'),
              ),
            ],
          ),
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
    List<ClothingItem> get filteredClothes {
    if (selectedFilter == null) return clothes;
    return clothes.where((item) => item.clothingType == selectedFilter).toList();
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

  Future<void> _generateOutfit() async {
    if (clothes.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kombin oluşturmak için en az 2 kıyafet ekle.')),
      );
      return;
    }

    final selectedContext = await _askContext();
    if (selectedContext == null) return;

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
                          // Fotoğraf açılamazsa (örn. desteklenmeyen format) burayı gösteriyoruz
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