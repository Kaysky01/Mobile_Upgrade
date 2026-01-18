import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dashboard_screen.dart';
import 'reports_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import 'news_screen.dart';
import 'login_screen.dart';
import '../services/google_auth_service.dart';
import '../services/auth_service.dart'; // Tambahkan import ini

class MoreMenuScreen extends StatefulWidget {
  const MoreMenuScreen({super.key});

  @override
  State<MoreMenuScreen> createState() => _MoreMenuScreenState();
}

class _MoreMenuScreenState extends State<MoreMenuScreen> {
  int _selectedIndex = 3;
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final AuthService _authService = AuthService(); // Inisialisasi AuthService

  String _userName = 'User Name';
  String _userEmail = 'user@example.com';
  String? _userPhotoUrl;
  String? _profilePhotoPath;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadProfilePhoto();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // PERBAIKAN: Cek auth_token sesuai standar AuthService kita
    final token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty) {
      // Ambil data dengan key yang sinkron dengan AuthService
      final userName = prefs.getString('user_name');
      final userEmail = prefs.getString('user_email');
      final loginMethod = prefs.getString('login_method');

      if (loginMethod == 'google') {
        await _googleAuthService.signInSilently();
        final userInfo = _googleAuthService.getUserInfo();
        if (userInfo != null) {
          setState(() {
            _userName = userInfo['displayName'] ?? userName ?? 'User Name';
            _userEmail = userInfo['email'] ?? userEmail ?? 'user@example.com';
            _userPhotoUrl = userInfo['photoUrl'];
          });
          return;
        }
      }

      setState(() {
        _userName = userName ?? 'User Name';
        _userEmail = userEmail ?? 'user@example.com';
        _userPhotoUrl = null; 
      });
    } else {
      setState(() {
        _userName = 'Guest';
        _userEmail = 'Silakan login untuk akses penuh';
        _userPhotoUrl = null;
      });
    }
  }

  void _loadUserInfo() async {
    await _checkLoginStatus();
  }

  Future<bool> _isUserLoggedIn() async {
    // Gunakan fungsi isLoggedIn dari AuthService yang sudah kita buat sebelumnya
    return await _authService.isLoggedIn();
  }

  Future<void> _loadProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhotoPath = prefs.getString('profile_photo_path');
    if (savedPhotoPath != null && savedPhotoPath.isNotEmpty) {
      final file = File(savedPhotoPath);
      if (await file.exists()) {
        setState(() {
          _profilePhotoPath = savedPhotoPath;
        });
      }
    }
  }

  void _handleLoginLogout() async {
    final isLoggedIn = await _isUserLoggedIn();

    if (!isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      ).then((_) {
        // Refresh data setelah kembali dari login
        _checkLoginStatus();
        _loadProfilePhoto();
      });
    } else {
      _showLogoutConfirmation();
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Gunakan fungsi logout global dari AuthService agar semua key dihapus bersih
              await _authService.logout();

              if (mounted) {
                Navigator.pop(context);
                setState(() {
                  _userName = 'Guest';
                  _userEmail = 'Silakan login untuk akses penuh';
                  _userPhotoUrl = null;
                  _profilePhotoPath = null;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Berhasil keluar'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Bagian Build tetap sama persis sesuai UI yang Anda kirim sebelumnya
    return Scaffold(
      backgroundColor: const Color(0xFF1453A3),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                      _loadProfilePhoto();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                          ? CircleAvatar(
                              radius: 30,
                              backgroundImage: _userPhotoUrl!.startsWith('http')
                                  ? NetworkImage(_userPhotoUrl!)
                                  : FileImage(File(_userPhotoUrl!))
                                      as ImageProvider,
                              backgroundColor: Colors.transparent,
                            )
                          : _profilePhotoPath != null &&
                                  _profilePhotoPath!.isNotEmpty
                              ? CircleAvatar(
                                  radius: 30,
                                  backgroundImage:
                                      FileImage(File(_profilePhotoPath!)),
                                  backgroundColor: Colors.transparent,
                                )
                              : const CircleAvatar(
                                  radius: 30,
                                  backgroundImage:
                                      AssetImage('assets/profil.png'),
                                  backgroundColor: Colors.transparent,
                                ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userEmail,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Menu Lainnya',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Profil Menu
                    _buildMenuCard(
                      icon: Icons.person,
                      title: 'Profil Saya',
                      subtitle: 'Kelola informasi profil Anda',
                      color: const Color(0xFF1453A3),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Berita Menu
                    _buildMenuCard(
                      icon: Icons.newspaper,
                      title: 'Berita',
                      subtitle: 'Lihat berita dan pengumuman terkini',
                      color: const Color(0xFFFFA726),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NewsScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Pengaturan Menu
                    _buildMenuCard(
                      icon: Icons.settings,
                      title: 'Pengaturan',
                      subtitle: 'Atur preferensi aplikasi',
                      color: const Color(0xFF66BB6A),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Bantuan Menu
                    _buildMenuCard(
                      icon: Icons.help,
                      title: 'Bantuan & Dukungan',
                      subtitle: 'Pusat bantuan dan FAQ',
                      color: const Color(0xFF42A5F5),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // Login/Logout Button
                    InkWell(
                      onTap: _handleLoginLogout,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _userName != 'Guest'
                              ? const Color(0xFFFFEBEE)
                              : const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _userName != 'Guest'
                                ? const Color(0xFFE74C3C).withOpacity(0.3)
                                : const Color(0xFF1453A3).withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _userName != 'Guest'
                                    ? const Color(0xFFE74C3C).withOpacity(0.2)
                                    : const Color(0xFF1453A3).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _userName != 'Guest'
                                    ? Icons.logout
                                    : Icons.login,
                                color: _userName != 'Guest'
                                    ? const Color(0xFFE74C3C)
                                    : const Color(0xFF1453A3),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _userName != 'Guest' ? 'Logout' : 'Login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _userName != 'Guest'
                                          ? const Color(0xFFE74C3C)
                                          : const Color(0xFF1453A3),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _userName != 'Guest'
                                        ? 'Keluar dari akun Anda'
                                        : 'Masuk untuk akses penuh',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                              color: _userName != 'Guest'
                                  ? const Color(0xFFE74C3C).withOpacity(0.5)
                                  : const Color(0xFF1453A3).withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // Widget Helper tetap sama
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (_selectedIndex == index) return;
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen())); break;
            case 1: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ReportsScreen())); break;
            case 2: Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())); break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1453A3),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.file_copy_outlined), activeIcon: Icon(Icons.file_copy), label: 'Laporan'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Notifikasi'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), activeIcon: Icon(Icons.menu), label: 'Lainnya'),
        ],
      ),
    );
  }
}