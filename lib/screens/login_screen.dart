import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'create_report_screen.dart';
import 'forgot_password_screen.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';

class LoginScreen extends StatefulWidget {
  final bool redirectToCreateReport;

  const LoginScreen({
    super.key,
    this.redirectToCreateReport = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final AuthService _authService = AuthService();


  @override
  void initState() {
    super.initState();
    // Tidak perlu auto-redirect, user akan login manual
  }

  Future<void> _loginWithEmail() async {
     print('LOGIN BUTTON DITEKAN');
  if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email dan Password harus diisi!'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() => _isLoading = true);

  bool success = false;

  try {
    success = await _authService.loginWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
    );
    print('LOGIN RESULT: $success');
  } catch (e) {
    success = false;
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  if (!mounted) return;

  if (!success) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login gagal. Email atau password salah'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Login berhasil!'),
      backgroundColor: Colors.green,
    ),
    
  );

  // ❗ JANGAN POP + PUSH TANPA DELAY
  await Future.delayed(const Duration(milliseconds: 300));

  if (!mounted) return;

  if (widget.redirectToCreateReport) {
    Navigator.pop(context, true);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateReportScreen()),
    );
  } else {
    Navigator.pop(context, true);
  }
}


  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final googleUser = await _googleAuthService.signInWithGoogle();

      if (googleUser != null && mounted) {
        // Simpan status login
        final prefs = await SharedPreferences.getInstance();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Login berhasil! Selamat datang ${googleUser.displayName ?? "User"}'),
            backgroundColor: Colors.green,
          ),
        );

        // Cek apakah perlu redirect ke create report
        if (widget.redirectToCreateReport) {
          // Pop dengan hasil true untuk memberi tahu dashboard login berhasil
          Navigator.pop(context, true);
          // Kemudian push ke create report screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateReportScreen()),
          );
        } else {
          // Pop kembali ke screen sebelumnya (Dashboard)
          Navigator.pop(context, true);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login gagal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient dengan pattern
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1453A3),
                  Color(0xFF2E78D4),
                  Color(0xFF1E88E5),
                ],
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.06),
                        child: Column(
                          children: [
                            SizedBox(height: screenHeight * 0.06),

                            // Logo Header
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 70,
                                height: 70,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.shield,
                                    size: 70,
                                    color: Color(0xFF1453A3),
                                  );
                                },
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.03),

                            // Welcome text
                            const Text(
                              'Selamat Datang',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'Academic Report System',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 15,
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.04),

                            // Sign In Card - Responsive
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(screenWidth * 0.05),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.06,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF212121),
                                    ),
                                  ),

                                  SizedBox(height: screenHeight * 0.025),

                                  // Email Field
                                  TextField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      hintText: 'E-mail',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: screenWidth * 0.036,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
                                        color: Colors.grey[600],
                                        size: screenWidth * 0.05,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFE0E0E0)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFE0E0E0)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF1453A3), width: 2),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.035,
                                        vertical: screenHeight * 0.018,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFFAFAFA),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                  ),

                                  SizedBox(height: screenHeight * 0.015),

                                  // Password Field
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      hintText: 'Password',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: screenWidth * 0.036,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outlined,
                                        color: Colors.grey[600],
                                        size: screenWidth * 0.05,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: Colors.grey[600],
                                          size: screenWidth * 0.05,
                                        ),
                                        onPressed: () => setState(() =>
                                            _obscurePassword =
                                                !_obscurePassword),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFE0E0E0)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFE0E0E0)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF1453A3), width: 2),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.035,
                                        vertical: screenHeight * 0.018,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFFAFAFA),
                                    ),
                                  ),

                                  // Lupa Password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ForgotPasswordScreen(),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.01,
                                          vertical: screenHeight * 0.005,
                                        ),
                                      ),
                                      child: Text(
                                        'Lupa Password?',
                                        style: TextStyle(
                                          color: const Color(0xFF1453A3),
                                          fontSize: screenWidth * 0.033,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: screenHeight * 0.015),

                                  // Login Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _loginWithEmail,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF1453A3),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: EdgeInsets.symmetric(
                                            vertical: screenHeight * 0.018),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              height: screenWidth * 0.045,
                                              width: screenWidth * 0.045,
                                              child:
                                                  const CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2),
                                            )
                                          : Text(
                                              'Login',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.038,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),

                                  SizedBox(height: screenHeight * 0.02),

                                  // Divider
                                  Row(
                                    children: [
                                      Expanded(
                                          child: Divider(
                                              color: Colors.grey[300],
                                              height: 1)),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: screenWidth * 0.03),
                                        child: Text(
                                          'atau',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: screenWidth * 0.03,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                          child: Divider(
                                              color: Colors.grey[300],
                                              height: 1)),
                                    ],
                                  ),

                                  SizedBox(height: screenHeight * 0.02),

                                  // Google Sign In Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          _isLoading ? null : _loginWithGoogle,
                                      icon: Image.network(
                                        'https://lh3.googleusercontent.com/COxitqgJr1sJnIDe8-jiKhxDx1FrYbtRHKJ9z_hELisAlapwE9LUPh6fcXIfb5vwpbMl4xl9H9TRFPc5NOO8Sb3VSgIBrfRYvW6cUA',
                                        height: screenWidth * 0.05,
                                        width: screenWidth * 0.05,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: screenWidth * 0.05,
                                            height: screenWidth * 0.05,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: Colors.grey[300]!),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'G',
                                                style: TextStyle(
                                                  color:
                                                      const Color(0xFF4285F4),
                                                  fontSize: screenWidth * 0.03,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      label: Text(
                                        'Sign in with Google',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.036,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF212121),
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                            vertical: screenHeight * 0.015),
                                        side: BorderSide(
                                            color: Colors.grey[300]!),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.025),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
