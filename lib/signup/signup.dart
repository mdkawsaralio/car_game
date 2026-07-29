import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../routes/routes.dart';
import '../services/connectivity_services.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool acceptedTerms = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ConnectivityService _connectivityService =
      Get.find<ConnectivityService>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    for (var c in [
      nameController,
      emailController,
      passwordController,
      confirmPasswordController,
    ]) {
      c.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _checkInternet() async {
    if (!await _connectivityService.checkConnection()) {
      _connectivityService.showNoInternetSnackbar();
      setState(() {
        errorMessage = 'No internet connection.';
        isLoading = false;
      });
      return false;
    }
    return true;
  }

  Future<void> _signUp() async {
    if (!await _checkInternet()) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final pass = passwordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (name.isEmpty) return _setError('Please enter your full name');
    if (email.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return _setError('Please enter a valid email address');
    }
    if (pass.length < 6) {
      return _setError('Password must be at least 6 characters');
    }
    if (pass != confirmPass) return _setError('Passwords do not match');
    if (!acceptedTerms) {
      return _setError('Please accept the Terms and Conditions');
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final creds = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );
      await creds.user?.updateDisplayName(name);
      await creds.user?.reload();

      Get.snackbar(
        '🎉 Welcome!',
        'Account created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.greenAccent.shade700,
        colorText: Colors.white,
      );

      Get.offAllNamed(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      _setError(
        e.code == 'network-request-failed'
            ? 'Network error.'
            : _getFirebaseErrorMessage(e.code),
      );
    } catch (_) {
      _setError('An unexpected error occurred.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _setError(String msg) => setState(() => errorMessage = msg);

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      default:
        return 'Sign up failed. Try again.';
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: !isLoading,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white54, size: 22),
        suffixIcon: suffix,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          // ignore: deprecated_member_use
          fillColor: Colors.white.withOpacity(0.05),
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Obx(
          () => SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!_connectivityService.isConnected.value)
                              Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.wifi_off,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'No Internet Connection',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.redAccent,
                                    Colors.red.shade900,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withOpacity(0.25),
                                    blurRadius: 40,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.directions_car_filled_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Create Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Start your racing journey today',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 32),

                            _buildField(
                              controller: nameController,
                              hint: 'Full Name',
                              icon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              controller: emailController,
                              hint: 'Email Address',
                              icon: Icons.mail_outline_rounded,
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              controller: passwordController,
                              hint: 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscure: !isPasswordVisible,
                              suffix: IconButton(
                                icon: Icon(
                                  isPasswordVisible
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  color: Colors.white38,
                                ),
                                onPressed: () => setState(
                                  () => isPasswordVisible = !isPasswordVisible,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              controller: confirmPasswordController,
                              hint: 'Confirm Password',
                              icon: Icons.lock_outline_rounded,
                              obscure: !isConfirmPasswordVisible,
                              suffix: IconButton(
                                icon: Icon(
                                  isConfirmPasswordVisible
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  color: Colors.white38,
                                ),
                                onPressed: () => setState(
                                  () => isConfirmPasswordVisible =
                                      !isConfirmPasswordVisible,
                                ),
                              ),
                            ),

                            if (errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                errorMessage!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Checkbox(
                                  value: acceptedTerms,
                                  activeColor: Colors.redAccent,
                                  checkColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.grey.shade700,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  onChanged: isLoading
                                      ? null
                                      : (v) => setState(
                                          () => acceptedTerms = v ?? false,
                                        ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: isLoading
                                        ? null
                                        : () => setState(
                                            () =>
                                                acceptedTerms = !acceptedTerms,
                                          ),
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 13,
                                        ),
                                        children: const [
                                          TextSpan(text: 'I agree to the '),
                                          TextSpan(
                                            text: 'Terms & Privacy Policy',
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.redAccent,
                                    strokeWidth: 2.5,
                                  )
                                : SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton(
                                      onPressed: _signUp,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account?',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
