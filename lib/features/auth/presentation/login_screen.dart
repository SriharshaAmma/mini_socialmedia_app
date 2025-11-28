import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../gen/assets.gen.dart';
import '../presentation/controllers/login_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoginMode = true; // Toggle between Login and Register

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      isLoginMode = !isLoginMode;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (isLoginMode) {
        // Login
        await ref.read(loginControllerProvider.notifier).login(
          emailCtrl.text.trim(),
          passwordCtrl.text.trim(),
        );
      } else {
        // Register
        await ref.read(loginControllerProvider.notifier).register(
          emailCtrl.text.trim(),
          passwordCtrl.text.trim(),
        );
      }

      if (mounted) {
        if (!isLoginMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        context.go('/feed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isLoginMode ? "Login" : "Registration"} failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(28),
            width: 380,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(blurRadius: 15, color: Colors.black12)
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Logo
                  Assets.images.logo.image(height: 100),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    isLoginMode ? '📸 Mini Social App' : 'Create Account',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  // Email Field
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !loginState.isLoading,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Password Field
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: true,
                    enabled: !loginState.isLoading,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (!isLoginMode && value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  // Confirm Password Field (only for Register mode)
                  if (!isLoginMode) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPasswordCtrl,
                      obscureText: true,
                      enabled: !loginState.isLoading,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != passwordCtrl.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Submit Button (Login/Register)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: loginState.isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.deepPurple,
                      ),
                      child: loginState.isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        isLoginMode ? 'Login' : 'Sign Up',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Toggle between Login and Register
                  TextButton(
                    onPressed: loginState.isLoading ? null : _toggleMode,
                    child: Text(
                      isLoginMode
                          ? "Don't have an account? Sign Up"
                          : "Already have an account? Login",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}