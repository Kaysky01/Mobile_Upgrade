import 'package:flutter/material.dart';

class ReportDetailScreen extends StatelessWidget {
  final Map<String, dynamic> report;

  const ReportDetailScreen({super.key, required this.report});

  // Helper untuk mengambil respons admin dengan aman
  String? _getAdminResponse() {
    // Cek berbagai kemungkinan key dari backend
    if (report['admin_response'] != null &&
        report['admin_response'].toString().isNotEmpty) {
      return report['admin_response'].toString();
    }
    // Jika status ditolak, cek alasan penolakan
    if (report['rejection_reason'] != null &&
        report['rejection_reason'].toString().isNotEmpty) {
      return report['rejection_reason'].toString();
    }
    // Jika ada key 'note' atau 'message' dari backend
    if (report['note'] != null && report['note'].toString().isNotEmpty) {
      return report['note'].toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final adminResponse = _getAdminResponse();
    
    // Ambil status dan pastikan string (handle null)
    final statusRaw = report['status']?.toString() ?? 'Pending';
    // Normalisasi status (kapitalisasi huruf pertama)
    final status = statusRaw.isNotEmpty 
        ? '${statusRaw[0].toUpperCase()}${statusRaw.substring(1)}' 
        : statusRaw;

    Color statusColor;
    IconData statusIcon;

    // UPDATE: Menambahkan case 'Selesai'
    switch (status) {
      case 'Disetujui':
   // Tambahkan ini agar Selesai warnanya hijau
        statusColor = const Color.fromARGB(255, 43, 202, 255);
        statusIcon = Icons.check_circle;
        break;
      case 'Selesai': // Tambahkan ini agar Selesai warnanya hijau
        statusColor = const Color(0xFF66BB6A);
        statusIcon = Icons.check_circle;
        break;
      case 'Diproses':
        statusColor = const Color(0xFFFFA726);
        statusIcon = Icons.autorenew;
        break;
      case 'Ditolak':
        statusColor = const Color(0xFFE74C3C);
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = const Color(0xFF42A5F5);
        statusIcon = Icons.info;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1453A3),
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER (FIX: Menambahkan Tombol Menu) ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Agar tombol ke pojok
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Detail Laporan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // FIX: Tombol Opsi Ditambahkan Disini
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () => _showOptionsMenu(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Container(
                width: double.infinity,
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
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withOpacity(0.4), width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ID Laporan
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!, width: 1),
                        ),
                        child: Text(
                          'ID: #${(report['id'] ?? '0000').toString().padLeft(4, '0')}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Title
                      Text(
                        report['title']?.toString() ?? 'Tanpa Judul',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Info Cards
                      _buildInfoCard(
                        icon: Icons.category,
                        label: 'Kategori',
                        value: report['category']?.toString() ?? '-',
                        color: const Color(0xFF1453A3),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.calendar_today,
                        label: 'Tanggal Laporan',
                        value: report['date']?.toString() ?? '-',
                        color: const Color(0xFF9575CD),
                      ),
                      // Cek null safety untuk imageCount
                      if ((report['imageCount'] ?? 0) > 0) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.attach_file,
                          label: 'Lampiran',
                          value: '${report['imageCount']} file',
                          color: const Color(0xFF4DD0E1),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Description Section
                      const Text(
                        'Deskripsi Lengkap',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!, width: 1.5),
                        ),
                        child: Text(
                          report['description']?.toString() ?? 'Tidak ada deskripsi',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                            height: 1.6,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Status Info Box
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              statusColor.withOpacity(0.08),
                              statusColor.withOpacity(0.03),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: statusColor, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  'Status Laporan',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _getStatusMessage(status),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // FIX: Menambahkan kondisi 'Selesai' agar rincian muncul
                      if (status == 'Diproses' || status == 'Disetujui' || status == 'Selesai') ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue[200]!, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.assignment, color: Colors.blue[700], size: 22),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Rincian Pelanggaran',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildProcessDetailRow('Reviewer', 'Timdis'),
                              const SizedBox(height: 10),
                              // Gunakan data real jika ada, jika tidak dummy
                              _buildProcessDetailRow('Tingkat', report['level'] ?? 'Sedang'),
                              const SizedBox(height: 16),
                              // Tampilkan pesan admin disini juga jika ada
                              if (adminResponse != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Catatan Reviewer:',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        adminResponse,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[800],
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ],

                      // Balasan Admin Section (Eksplisit)
                      if (adminResponse != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF1453A3).withOpacity(0.08),
                                const Color(0xFF1453A3).withOpacity(0.03),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF1453A3).withOpacity(0.3),
                              width: 1.5
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1453A3).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.admin_panel_settings,
                                      color: Color(0xFF1453A3),
                                      size: 24
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Balasan Admin',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1453A3),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          report['admin_name'] ?? 'Admin',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (report['response_date'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[300]!, width: 1),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            report['response_date'].toString(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  adminResponse,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Tambahan padding bawah agar tidak mentok
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Helper (Build Info Card, Detail Row) Tetap Sama...
  // Tapi saya sertakan agar full code bisa copy paste tanpa error

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'Selesai': // Pesan khusus untuk status Selesai
        return 'Laporan Anda telah selesai diproses dan ditindaklanjuti oleh tim kami. Terima kasih atas kontribusi Anda dalam menjaga lingkungan yang lebih baik.';
      case 'Disetujui': // Handle message untuk Selesai
        return 'Laporan Anda telah disetujui dan diselesaikan. Terima kasih atas partisipasi Anda dalam menjaga integritas.';
      case 'Diproses':
        return 'Laporan Anda sedang dalam tahap verifikasi. Tim kami akan segera menghubungi Anda jika diperlukan informasi tambahan.';
      case 'Ditolak':
        return 'Laporan Anda ditolak karena tidak memenuhi kriteria verifikasi. Silakan ajukan laporan baru dengan bukti yang lebih lengkap.';
      default:
        return 'Laporan Anda telah diterima dan akan segera diproses oleh tim verifikasi.';
    }
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Opsi Laporan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFF1453A3)),
              title: const Text('Bagikan Laporan'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur Bagikan - Coming Soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Color(0xFF66BB6A)),
              title: const Text('Unduh PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur Download PDF - Coming Soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Color(0xFFE74C3C)),
              title: const Text('Hapus Laporan'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Laporan'),
        content: const Text('Apakah Anda yakin ingin menghapus laporan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup Dialog
              Navigator.pop(context); // Kembali ke layar sebelumnya
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Laporan berhasil dihapus'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}