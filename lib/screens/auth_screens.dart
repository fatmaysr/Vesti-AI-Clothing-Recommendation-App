import 'package:flutter/material.dart';
import '../supabase_client.dart';
import '../models.dart';
import 'wardrobe_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Uygulamanın "kapısı": kullanıcı giriş yapmışsa dolabı, yapmamışsa
// giriş ekranını gösterir.
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