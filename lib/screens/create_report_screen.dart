import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dashboard_screen.dart';
import 'reports_screen.dart';
import 'notifications_screen.dart';
import 'more_menu_screen.dart';
import 'report_detail_screen.dart';
import 'login_screen.dart';
import 'map_location_picker.dart';
import '../services/image_cache_service.dart';
import '../services/report_service.dart';
import '../services/google_auth_service.dart';
import '../models/report_model.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _customCategoryController =
      TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  String _selectedCategory = '';
  DateTime? _selectedDate;
  bool _showCustomCategory = false;
  LatLng? _selectedLocationCoordinates;

  // Media files
  List<MediaItem> _mediaItems = [];
  final ImagePicker _picker = ImagePicker();

  int _selectedIndex = 1;
  final ImageCacheService _imageCacheService = ImageCacheService();
  final ReportService _reportService = ReportService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  final List<String> _categories = [
    'Plagiarisme',
    'Menyontek',
    'Titip Absen',
    'Kecurangan Ujian',
    'Pemalsuan Data',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _loadCachedMedia();
  }

  Future<void> _loadCachedMedia() async {
    final mediaType = await _imageCacheService.getMediaType();

    if (mediaType == 'image') {
      // Load image - FIX: Use async method
      final hasImage = await _imageCacheService.hasImageAsync();
      if (hasImage) {
        final cachedImage = await _imageCacheService.getCachedImageAsync();
        if (cachedImage != null) {
          setState(() {
            _mediaItems.add(MediaItem(
              file: cachedImage,
              type: MediaType.image,
            ));
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Foto dari login berhasil dimuat!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          });
        }
      }
    } else if (mediaType == 'video') {
      // Load video
      final cachedVideo = await _imageCacheService.getCachedVideo();
      if (cachedVideo != null) {
        final controller = VideoPlayerController.file(cachedVideo);

        try {
          await controller.initialize();

          setState(() {
            _mediaItems.add(MediaItem(
              file: cachedVideo,
              type: MediaType.video,
              controller: controller,
            ));
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video dari login berhasil dimuat!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          });
        } catch (e) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading video: $e'),
                backgroundColor: Colors.red,
              ),
            );
          });
        }
      }
    }

    final hasMedia = await _imageCacheService.hasMedia();

    if (hasMedia) {
      // Show info banner
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Media bukti dari kamera berhasil dimuat! ${_mediaItems.length} file siap dilampirkan.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
    // Clear cache after loading
    await _imageCacheService.clearCache();
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _mediaItems.add(MediaItem(
          file: File(image.path),
          type: MediaType.image,
        ));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto berhasil ditambahkan'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickImagesFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage(
      imageQuality: 85,
    );

    if (images.isNotEmpty) {
      setState(() {
        for (var image in images) {
          if (_mediaItems.length < 5) {
            _mediaItems.add(MediaItem(
              file: File(image.path),
              type: MediaType.image,
            ));
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${images.length} foto berhasil ditambahkan'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _recordVideoFromCamera() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 2),
    );

    if (video != null) {
      final videoFile = File(video.path);
      final controller = VideoPlayerController.file(videoFile);

      try {
        await controller.initialize();

        setState(() {
          _mediaItems.add(MediaItem(
            file: videoFile,
            type: MediaType.video,
            controller: controller,
          ));
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video berhasil direkam'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickVideoFromGallery() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      final videoFile = File(video.path);
      final controller = VideoPlayerController.file(videoFile);

      try {
        await controller.initialize();

        setState(() {
          _mediaItems.add(MediaItem(
            file: videoFile,
            type: MediaType.video,
            controller: controller,
          ));
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video berhasil ditambahkan'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMediaSourceDialog() {
    if (_mediaItems.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 5 media (foto/video)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tambah Media Bukti',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih jenis media yang ingin ditambahkan (${_mediaItems.length}/5)',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              // Grid Menu
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildMediaOption(
                    icon: Icons.camera_alt,
                    label: 'Ambil Foto',
                    color: const Color(0xFF1453A3),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                  _buildMediaOption(
                    icon: Icons.photo_library,
                    label: 'Galeri Foto',
                    color: const Color(0xFF2E78D4),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImagesFromGallery();
                    },
                  ),
                  _buildMediaOption(
                    icon: Icons.videocam,
                    label: 'Rekam Video',
                    color: const Color(0xFFE74C3C),
                    onTap: () {
                      Navigator.pop(context);
                      _recordVideoFromCamera();
                    },
                  ),
                  _buildMediaOption(
                    icon: Icons.video_library,
                    label: 'Galeri Video',
                    color: const Color(0xFFFF6B6B),
                    onTap: () {
                      Navigator.pop(context);
                      _pickVideoFromGallery();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
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
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLocation: _selectedLocationCoordinates,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocationCoordinates = result;
        _lokasiController.text =
            'Lat: ${result.latitude.toStringAsFixed(6)}, Long: ${result.longitude.toStringAsFixed(6)}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi berhasil dipilih dari peta'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeMedia(int index) {
    final item = _mediaItems[index];
    if (item.type == MediaType.video && item.controller != null) {
      item.controller!.dispose();
    }

    setState(() {
      _mediaItems.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Media berhasil dihapus'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _submitReport() async {
    // Validasi
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul laporan harus dipilih!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_deskripsiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deskripsi laporan harus diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCategory == 'Lainnya' &&
        _customCategoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori lainnya harus diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal kejadian harus dipilih!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_lokasiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi kejadian harus diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // CEK LOGIN - Cek dari SharedPreferences dan Google Sign In
  final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('token');
    final isLoggedIn = token != null && token.isNotEmpty;

    if (!isLoggedIn) {
      // Jika belum login, tampilkan dialog konfirmasi
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Login Diperlukan',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
              'Anda harus login terlebih dahulu untuk mengirim laporan. Data laporan Anda akan tersimpan. Apakah Anda ingin login sekarang?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1453A3),
              ),
              child: const Text('Login', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (result == true && mounted) {
        // Simpan data laporan sementara ke ImageCacheService termasuk tanggal
        final months = [
          'Januari',
          'Februari',
          'Maret',
          'April',
          'Mei',
          'Juni',
          'Juli',
          'Agustus',
          'September',
          'Oktober',
          'November',
          'Desember'
        ];
        final dateStr = _selectedDate != null
            ? '${_selectedDate!.day} ${months[_selectedDate!.month - 1]} ${_selectedDate!.year}'
            : '';

        // Get final category (gunakan custom jika \"Lainnya\")
        final finalCategory = _selectedCategory == 'Lainnya'
            ? _customCategoryController.text
            : _selectedCategory;

        await _imageCacheService.cacheReportData(
          title: finalCategory,
          description: _deskripsiController.text,
          category: _selectedCategory,
          customCategory: _selectedCategory == 'Lainnya'
              ? _customCategoryController.text
              : null,
          selectedDate: dateStr,
          location: _lokasiController.text,
        );

        // Arahkan ke login screen
        final loginSuccess = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const LoginScreen(redirectToCreateReport: false),
          ),
        );

        // Jika login berhasil, langsung submit dan navigate ke detail
        if (loginSuccess == true && mounted) {
          // Tampilkan loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );

          // Delay sebentar untuk UX
          await Future.delayed(const Duration(milliseconds: 200));

          // Tutup loading
          if (mounted) Navigator.pop(context);

          // Auto submit dan navigate ke detail
          await _autoSubmitAfterLogin();
        }
      }
      return;
    }

    // Jika sudah login, lanjutkan submit
    _proceedWithSubmit();
  }

  // Method untuk auto submit setelah login (langsung ke detail laporan)
  Future<void> _autoSubmitAfterLogin() async {
    // Load data dari cache
    final cachedData = await _imageCacheService.getCachedReportData();

    if (cachedData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan saat memuat data laporan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Gunakan data dari cache
    final title = cachedData['title'] ?? '';
    final description = cachedData['description'] ?? _deskripsiController.text;
    final category = cachedData['category'] ?? _selectedCategory;
    final customCategory = cachedData['customCategory'];
    final dateStr = cachedData['selectedDate'] ?? '';

    // Get final category (gunakan custom jika "Lainnya")
    final finalCategory =
        category == 'Lainnya' ? (customCategory ?? category) : category;

  final success = await _reportService.createReport(
  categoryId: _categories.indexOf(finalCategory) + 1,
  title: finalCategory,
  description: description,
  location: cachedData['location'],
);

if (!success) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Gagal mengirim laporan'),
      backgroundColor: Colors.red,
    ),
  );
  return;
}

// Clear cached report data
await _imageCacheService.clearReportData();

// Notifikasi sukses
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('✓ Laporan berhasil dikirim!'),
    backgroundColor: Colors.green,
    duration: Duration(seconds: 2),
  ),
);

// 🔁 Ke LIST laporan (ambil dari API)
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => const ReportsScreen()),
);
}

  // Method terpisah untuk proses submit setelah login
  void _proceedWithSubmit() {
    final photoCount =
        _mediaItems.where((m) => m.type == MediaType.image).length;
    final videoCount =
        _mediaItems.where((m) => m.type == MediaType.video).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apakah Anda yakin ingin mengirim laporan ini?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.photo,
                          size: 16, color: Color(0xFF1453A3)),
                      const SizedBox(width: 8),
                      Text('$photoCount Foto'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.videocam,
                          size: 16, color: Color(0xFFE74C3C)),
                      const SizedBox(width: 8),
                      Text('$videoCount Video'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final now = DateTime.now();
              final months = [
                'Januari',
                'Februari',
                'Maret',
                'April',
                'Mei',
                'Juni',
                'Juli',
                'Agustus',
                'September',
                'Oktober',
                'November',
                'Desember'
              ];
              final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';

              // Get final category (gunakan custom jika "Lainnya")
              final finalCategory = _selectedCategory == 'Lainnya'
                  ? _customCategoryController.text
                  : _selectedCategory;

              Navigator.pop(context); // tutup dialog

showDialog(
  context: context,
  barrierDismissible: false,
  builder: (_) => const Center(
    child: CircularProgressIndicator(),
  ),
);


final success = await _reportService.createReport(
  categoryId: _categories.indexOf(finalCategory) + 1,
  title: finalCategory,
  description: _deskripsiController.text,
  location: _lokasiController.text,
);

Navigator.pop(context); // tutup loading

if (!success) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Gagal mengirim laporan'),
      backgroundColor: Colors.red,
    ),
  );
  return;
}

ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('✓ Laporan berhasil dikirim'),
    backgroundColor: Colors.green,
    duration: Duration(seconds: 2),
  ),
);

// 🔁 ke list laporan (API source of truth)
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => const ReportsScreen()),
);


              // Navigasi ke ReportDetailScreen dengan data laporan baru

            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1453A3),
            ),
            child: const Text('Kirim', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1453A3),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Laporan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Buat Laporan Baru',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul (Kategori)
                      const Text('Judul',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory.isEmpty
                                ? null
                                : _selectedCategory,
                            hint: Text('Pilih kategori',
                                style: TextStyle(color: Colors.grey[400])),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            items: _categories.map((category) {
                              return DropdownMenuItem<String>(
                                  value: category, child: Text(category));
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value ?? '';
                                _showCustomCategory = value == 'Lainnya';
                                if (value != 'Lainnya') {
                                  _customCategoryController.clear();
                                }
                              });
                            },
                          ),
                        ),
                      ),

                      // Custom Category TextField (muncul kalau pilih "Lainnya")
                      if (_showCustomCategory) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _customCategoryController,
                          decoration: InputDecoration(
                            hintText: 'Masukkan kategori lainnya',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                            prefixIcon: const Icon(Icons.edit,
                                color: Color(0xFF1453A3)),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Deskripsi
                      const Text('Deskripsi',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _deskripsiController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: 'Jelaskan detail laporan Anda',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Tanggal Kejadian
                      const Text('Tanggal Kejadian',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF1453A3),
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Color(0xFF1453A3)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDate == null
                                      ? 'Pilih tanggal kejadian'
                                      : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                                  style: TextStyle(
                                    color: _selectedDate == null
                                        ? Colors.grey[400]
                                        : Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (_selectedDate != null)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedDate = null;
                                    });
                                  },
                                  child: const Icon(Icons.clear,
                                      size: 20, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Lokasi Kejadian
                      const Text('Lokasi Kejadian',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _lokasiController,
                              decoration: InputDecoration(
                                hintText:
                                    'Masukkan lokasi atau pilih dari peta',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(16),
                                prefixIcon: const Icon(Icons.location_on,
                                    color: Color(0xFF1453A3)),
                                suffixIcon: _lokasiController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            _lokasiController.clear();
                                            _selectedLocationCoordinates = null;
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1453A3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.map, color: Colors.white),
                              onPressed: _openMapPicker,
                              tooltip: 'Pilih dari Peta',
                            ),
                          ),
                        ],
                      ),
                      if (_selectedLocationCoordinates != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Lokasi dipilih dari peta',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Media Section
                      Row(
                        children: [
                          const Text('Bukti Media',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1453A3).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_mediaItems.length}/5 media',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1453A3),
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Add Media Button
                      GestureDetector(
                        onTap: _showMediaSourceDialog,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _mediaItems.length >= 5
                                  ? Colors.grey[300]!
                                  : const Color(0xFF1453A3).withOpacity(0.3),
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: _mediaItems.length >= 5
                                    ? Colors.grey[400]
                                    : const Color(0xFF1453A3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _mediaItems.length >= 5
                                    ? 'Maksimal 5 media'
                                    : 'Tap untuk tambah foto/video',
                                style: TextStyle(
                                  color: _mediaItems.length >= 5
                                      ? Colors.grey[500]
                                      : Colors.grey[700],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo,
                                      size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text('Foto',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500])),
                                  const SizedBox(width: 12),
                                  Icon(Icons.videocam,
                                      size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text('Video',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500])),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Media Grid
                      if (_mediaItems.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: _mediaItems.length,
                          itemBuilder: (context, index) {
                            final item = _mediaItems[index];
                            return _buildMediaPreview(item, index);
                          },
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Tombol Kirim
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1453A3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Kirim Laporan',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildMediaPreview(MediaItem item, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.type == MediaType.image
                ? Image.file(
                    item.file,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : item.controller != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          VideoPlayer(item.controller!),
                          Center(
                            child: IconButton(
                              icon: Icon(
                                item.controller!.value.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: Colors.white,
                                size: 50,
                              ),
                              onPressed: () {
                                setState(() {
                                  item.controller!.value.isPlaying
                                      ? item.controller!.pause()
                                      : item.controller!.play();
                                });
                              },
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: Icon(Icons.error, color: Colors.white),
                      ),
          ),
        ),

        // Type Badge
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: item.type == MediaType.image
                  ? const Color(0xFF1453A3).withOpacity(0.9)
                  : const Color(0xFFE74C3C).withOpacity(0.9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.type == MediaType.image ? Icons.photo : Icons.videocam,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                if (item.type == MediaType.video && item.controller != null)
                  Text(
                    '${item.controller!.value.duration.inSeconds}s',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        ),

        // Remove Button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _removeMedia(index),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
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
            case 0:
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DashboardScreen()));
              break;
            case 1:
              // FIX: Navigasi ke Reports (list), bukan create lagi
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ReportsScreen()));
              break;
            case 2:
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationsScreen()));
              break;
            case 3:
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MoreMenuScreen()));
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF1453A3),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda'),
          BottomNavigationBarItem(
              icon: Icon(Icons.file_copy_outlined),
              activeIcon: Icon(Icons.file_copy),
              label: 'Laporan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Notifikasi'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              activeIcon: Icon(Icons.menu),
              label: 'Lainnya'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _deskripsiController.dispose();
    _customCategoryController.dispose();
    _lokasiController.dispose();
    for (var item in _mediaItems) {
      if (item.type == MediaType.video && item.controller != null) {
        item.controller!.dispose();
      }
    }
    super.dispose();
  }
}

// Model untuk Media Item
class MediaItem {
  final File file;
  final MediaType type;
  final VideoPlayerController? controller;

  MediaItem({
    required this.file,
    required this.type,
    this.controller,
  });
}

enum MediaType { image, video }
