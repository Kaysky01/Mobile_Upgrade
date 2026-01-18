import 'package:flutter/material.dart';
import 'package:pelaporan_akademik/services/auth_service.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'reports_screen.dart';
import 'notifications_screen.dart';
import 'more_menu_screen.dart';
import 'news_screen.dart';
import 'login_screen.dart';
import 'create_report_screen.dart';
import 'profile_screen.dart';
import 'help_support_screen.dart';
import 'settings_screen.dart';
import '../services/google_auth_service.dart';
import '../services/image_cache_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final ImageCacheService _imageCacheService = ImageCacheService();

  String _userName = 'User Name';
  String _userEmail = 'user@example.com';
  String? _userPhotoUrl; // NEW: Tambah photo URL
  String? _profilePhotoPath; // Foto profil lokal dari SharedPreferences

  // Media yang sudah diambil
  File? _capturedMediaFile;
  bool _isMediaVideo = false;
  VideoPlayerController? _videoPreviewController;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadProfilePhoto();
  }

  // Cek status login dan load user info
Future<void> _checkLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  if (token != null && token.isNotEmpty) {
    // Ambil data yang disimpan oleh AuthService saat login berhasil
    final String userName = prefs.getString('user_name') ?? 'User';
    final String userEmail = prefs.getString('user_email') ?? '';
    final String? loginMethod = prefs.getString('login_method'); // Pastikan ini disimpan saat login

    if (loginMethod == 'google') {
      // Jika login via google, coba refresh data google jika perlu
      await _googleAuthService.signInSilently();
      final userInfo = _googleAuthService.getUserInfo();
      if (userInfo != null) {
        setState(() {
          _userName = userInfo['displayName'] ?? userName;
          _userEmail = userInfo['email'] ?? userEmail;
          _userPhotoUrl = userInfo['photoUrl'];
        });
        return;
      }
    }

    // Jika login via Email/Sanctum
    setState(() {
      _userName = userName;
      _userEmail = userEmail;
      _userPhotoUrl = null; // Email login biasanya tidak punya URL foto langsung dari API Laravel kecuali diset
    });
  } else {
    // STATUS GUEST
    setState(() {
      _userName = 'Guest';
      _userEmail = 'Silakan login untuk melapor';
      _userPhotoUrl = null;
    });
  }
}

  // Memuat foto profil yang tersimpan
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

  void _onNavBarTap(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Sudah di Dashboard
        break;
      case 1:
        // FIX: Ganti CreateReportScreen menjadi ReportsScreen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReportsScreen()),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MoreMenuScreen()),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
    }
  }

  // Handle pembuatan laporan - langsung ke create report (cek login nanti saat submit)
  void _handleCreateReport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Upload Bukti',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pilih sumber file yang ingin Anda upload',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Kamera Section
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Dari Kamera',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMediaOption(
                        icon: Icons.camera_alt,
                        label: 'Foto',
                        color: const Color(0xFF1453A3),
                        onTap: () async {
                          Navigator.pop(context);
                          await _captureMedia(ImageSource.camera,
                              isVideo: false);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMediaOption(
                        icon: Icons.videocam,
                        label: 'Video',
                        color: const Color(0xFFE74C3C),
                        onTap: () async {
                          Navigator.pop(context);
                          await _captureMedia(ImageSource.camera,
                              isVideo: true);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Galeri Section
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Dari Galeri',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildMediaOption(
                        icon: Icons.photo_library,
                        label: 'Foto',
                        color: const Color(0xFF66BB6A),
                        onTap: () async {
                          Navigator.pop(context);
                          await _captureMedia(ImageSource.gallery,
                              isVideo: false);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMediaOption(
                        icon: Icons.video_library,
                        label: 'Video',
                        color: const Color(0xFFFFA726),
                        onTap: () async {
                          Navigator.pop(context);
                          await _captureMedia(ImageSource.gallery,
                              isVideo: true);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureMedia(ImageSource source,
      {required bool isVideo}) async {
    final ImagePicker picker = ImagePicker();

    try {
      if (isVideo) {
        final XFile? video = await picker.pickVideo(
          source: source,
          maxDuration: const Duration(minutes: 2),
        );

        if (video != null) {
          // Simpan video ke cache
          await _imageCacheService.cacheVideo(video.path);

          // Initialize video player untuk preview
          final controller = VideoPlayerController.file(File(video.path));
          try {
            await controller.initialize();
            setState(() {
              _capturedMediaFile = File(video.path);
              _isMediaVideo = true;
              _videoPreviewController = controller;
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Video berhasil diambil! Tekan tombol Laporan untuk melanjutkan'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal memuat video: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } else {
        final XFile? photo = await picker.pickImage(
          source: source,
          imageQuality: 85,
        );

        if (photo != null) {
          // Simpan foto ke cache
          await _imageCacheService.cacheImage(photo.path);

          setState(() {
            _capturedMediaFile = File(photo.path);
            _isMediaVideo = false;
            _videoPreviewController?.dispose();
            _videoPreviewController = null;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Foto berhasil diambil! Tekan tombol Laporan untuk melanjutkan'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil ${isVideo ? "video" : "foto"}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Cari baris 251 di dashboard_screen.dart Anda dan ganti dengan ini:

void _openCreateReport() async {

  // 3. JIKA SUDAH LOGIN, barulah jalankan logika buka form laporan
  if (_capturedMediaFile != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateReportScreen(),
      ),
    ).then((_) {
      // Bersihkan media setelah kembali dari layar laporan
      setState(() {
        _capturedMediaFile = null;
        _isMediaVideo = false;
        _videoPreviewController?.dispose();
        _videoPreviewController = null;
      });
      _checkLoginStatus();
      _loadProfilePhoto();
    });
  } else {
    // Jika belum ada foto/video yang diambil, buka pilihan kamera/galeri
    _handleCreateReport();
  }
}

  @override
  void dispose() {
    _videoPreviewController?.dispose();
    super.dispose();
  }

 void _showLogoutDialog() {
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
            Navigator.pop(context);
            
            // Gunakan AuthService agar sinkron
            final authService = AuthService();
            await authService.logout();

            if (mounted) {
              setState(() {
                _userName = 'Guest';
                _userEmail = 'Silakan login untuk melapor';
                _userPhotoUrl = null;
                _profilePhotoPath = null;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logout berhasil!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C)),
          child: const Text('Logout', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF1453A3),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Header - FIX: Gunakan foto profil dari asset
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Logo Polinela di pojok kiri
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.shield,
                          size: 45,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Academic Report',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Sistem Siap Polinela',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                      // Reload foto profil setelah kembali dari ProfileScreen
                      _loadProfilePhoto();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                          ? CircleAvatar(
                              radius: 23,
                              backgroundImage: _userPhotoUrl!.startsWith('http')
                                  ? NetworkImage(_userPhotoUrl!)
                                  : FileImage(File(_userPhotoUrl!))
                                      as ImageProvider,
                              backgroundColor: Colors.transparent,
                            )
                          : _profilePhotoPath != null &&
                                  _profilePhotoPath!.isNotEmpty
                              ? CircleAvatar(
                                  radius: 23,
                                  backgroundImage:
                                      FileImage(File(_profilePhotoPath!)),
                                  backgroundColor: Colors.transparent,
                                )
                              : const CircleAvatar(
                                  radius: 23,
                                  backgroundImage:
                                      AssetImage('assets/profil.png'),
                                  backgroundColor: Colors.transparent,
                                ),
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
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 20, bottom: 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                      // Card Upload File - Full Width
                      // Card dengan icon upload
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: InkWell(
                          onTap: () {
                            _handleCreateReport();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: double.infinity,
                            height: _capturedMediaFile != null ? 280 : 220,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF1453A3), Color(0xFF2E78D4)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF1453A3).withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: _capturedMediaFile != null
                                ? Stack(
                                    children: [
                                      // Full gambar/video sebagai background
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: _isMediaVideo
                                            ? (_videoPreviewController !=
                                                        null &&
                                                    _videoPreviewController!
                                                        .value.isInitialized)
                                                ? Container(
                                                    color: Colors.black,
                                                    child: Center(
                                                      child: AspectRatio(
                                                        aspectRatio:
                                                            _videoPreviewController!
                                                                .value
                                                                .aspectRatio,
                                                        child: VideoPlayer(
                                                            _videoPreviewController!),
                                                      ),
                                                    ),
                                                  )
                                                : Container(
                                                    color: Colors.black87,
                                                    child: const Center(
                                                      child: Icon(
                                                          Icons.videocam,
                                                          size: 80,
                                                          color:
                                                              Colors.white70),
                                                    ),
                                                  )
                                            : Image.file(
                                                _capturedMediaFile!,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                      // Overlay gradient untuk teks
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black.withOpacity(0.3),
                                              Colors.black.withOpacity(0.7),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Badge/label di pojok kanan atas
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _isMediaVideo
                                                ? const Color(0xFFE74C3C)
                                                : const Color(0xFF66BB6A),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _isMediaVideo
                                                    ? Icons.videocam
                                                    : Icons.photo_camera,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _isMediaVideo
                                                    ? 'Video'
                                                    : 'Foto',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Tombol X untuk hapus/batal di pojok kiri atas
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                _capturedMediaFile = null;
                                                _isMediaVideo = false;
                                                _videoPreviewController
                                                    ?.dispose();
                                                _videoPreviewController = null;
                                              });
                                              // Hapus dari cache juga
                                              _imageCacheService.clearCache();
                                            },
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withOpacity(0.6),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.3),
                                                    blurRadius: 8,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                size: 20,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Play icon untuk video
                                      if (_isMediaVideo)
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.3),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow,
                                              size: 48,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      // Teks di bawah
                                      Positioned(
                                        bottom: 16,
                                        left: 16,
                                        right: 16,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Bukti siap diupload!',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Tekan tombol "Buat Laporan" di bawah',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.cloud_upload_outlined,
                                          size: 56,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      const Text(
                                        'Upload File',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Pilih foto atau video dari perangkat',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Button Laporan dengan padding
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              _openCreateReport();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _capturedMediaFile != null
                                  ? const Color(0xFF66BB6A)
                                  : const Color(0xFF1453A3),
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shadowColor: (_capturedMediaFile != null
                                      ? const Color(0xFF66BB6A)
                                      : const Color(0xFF1453A3))
                                  .withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_capturedMediaFile != null) ...[
                                  const Icon(Icons.check_circle, size: 18),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  'Laporkan',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Berita Terkini Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Berita Terkini',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const NewsScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Lihat Semua',
                                style: TextStyle(
                                  color: Color(0xFF1453A3),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // News Cards
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildNewsCard(
                              title:
                                  'Politeknik Negeri Lampung Raih Akreditasi Unggul',
                              date: '24 Desember 2024',
                              category: 'Prestasi',
                              imageUrl: 'https://via.placeholder.com/150',
                            ),
                            const SizedBox(height: 12),
                            _buildNewsCard(
                              title:
                                  'Workshop Pengembangan Aplikasi Mobile di Polinela',
                              date: '22 Desember 2024',
                              category: 'Kegiatan',
                              imageUrl: 'https://via.placeholder.com/150',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildNewsCard(
                        title: 'Mahasiswa Polinela Juara Kompetisi Nasional',
                        date: '20 Desember 2024',
                        category: 'Prestasi',
                        imageUrl: 'https://via.placeholder.com/150',
                      ),

                      const SizedBox(height: 30),

                      // Laporan Terbaru Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Laporan Terbaru',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ReportsScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Lihat Semua',
                                style: TextStyle(
                                  color: Color(0xFF1453A3),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // List Laporan
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildReportCard(
                              title: 'Kecurangan Ujian Tengah Semester',
                              status: 'Ujian',
                              statusColor: const Color(0xFF9575CD),
                              date: '23 Oktober 2025',
                              icon: Icons.assignment,
                            ),
                            const SizedBox(height: 12),
                            _buildReportCard(
                              title: 'Plagiarisme Tugas Akhir',
                              status: 'Tugas',
                              statusColor: const Color(0xFF4DD0E1),
                              date: '22 Oktober 2025',
                              icon: Icons.description,
                            ),
                            const SizedBox(height: 12),
                            _buildReportCard(
                              title: 'Kerjasama Tidak Sah',
                              status: 'Kerjasama',
                              statusColor: const Color(0xFFFF8A65),
                              date: '21 Oktober 2025',
                              icon: Icons.people,
                            ),
                          ],
                        ),
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

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String count,
    required String label,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                // FIX: Tambah maxLines dan overflow handling
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11, // Kurangi dari 12 ke 11
                    color: Colors.black54,
                    height: 1.2, // Tambahkan line height
                  ),
                  maxLines: 2, // Max 2 baris
                  overflow:
                      TextOverflow.ellipsis, // Tambah ... jika terlalu panjang
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard({
    required String title,
    required String date,
    required String category,
    required String imageUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Icon(
                Icons.newspaper,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1453A3).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF1453A3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String status,
    required Color statusColor,
    required String date,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: statusColor,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: const Color(0xFF1453A3),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_copy_outlined),
            activeIcon: Icon(Icons.file_copy),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notifikasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            activeIcon: Icon(Icons.menu),
            label: 'Lainnya',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1453A3),
                  Color(0xFF2E78D4),
                ],
              ),
            ),
            child: SafeArea(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FIX: Foto Profil di Drawer - gunakan asset
                    const CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage('assets/profil.png'),
                      backgroundColor: Colors.transparent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _userEmail,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profil Saya'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfileScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Beranda'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.file_copy),
                  title: const Text('Laporan Saya'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ReportsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifikasi'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NotificationsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.newspaper),
                  title: const Text('Berita'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NewsScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Pengaturan'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Bantuan'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Tampilkan Login atau Logout berdasarkan status
          _googleAuthService.isSignedIn()
              ? ListTile(
                  leading: const Icon(Icons.logout, color: Color(0xFFE74C3C)),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Color(0xFFE74C3C)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog();
                  },
                )
              : ListTile(
                  leading: const Icon(Icons.login, color: Color(0xFF1453A3)),
                  title: const Text(
                    'Login',
                    style: TextStyle(color: Color(0xFF1453A3)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    ).then((_) {
                      // Refresh user info setelah login
                      _checkLoginStatus();
                      _loadProfilePhoto();
                    });
                  },
                ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
