import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import '../../../services/auth_service.dart';

class PerangkatScreen extends StatefulWidget {
  const PerangkatScreen({super.key});

  @override
  State<PerangkatScreen> createState() => _PerangkatScreenState();
}

class _PerangkatScreenState extends State<PerangkatScreen> {
  bool _isLoading = true;
  List<dynamic> _apiKeys = [];
  String? _currentKeyId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final keys = await AuthService.listMyApiKeys();
      // Get current device API key ID to highlight it
      final currentApiKey = await AuthService.getDeviceApiKey();
      
      if (mounted) {
        setState(() {
          // Urutkan berdasarkan lastRequest (aktivitas terakhir) secara descending
          _apiKeys = List.from(keys);
          _apiKeys.sort((a, b) {
            final timeA = DateTime.tryParse(a['lastRequest']?.toString() ?? '') ?? DateTime(2000);
            final timeB = DateTime.tryParse(b['lastRequest']?.toString() ?? '') ?? DateTime(2000);
            return timeB.compareTo(timeA);
          });
          _isLoading = false;
        });
        
        // Coba baca ID lokal
        final localKeyId = await AuthService.getDeviceApiKeyId(); // Butuh method ini di auth_service
        if (localKeyId != null && mounted) {
          setState(() => _currentKeyId = localKeyId);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getErrorMessage(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteKey(String keyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Perangkat?'),
        content: const Text('Perangkat ini tidak akan bisa mengakses aplikasi lagi kecuali login ulang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await AuthService.deleteApiKey(keyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perangkat berhasil dihapus')),
        );
        _loadData(); // Reload list
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getErrorMessage(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perangkat Tertaut'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _apiKeys.isEmpty
              ? const Center(child: Text('Tidak ada perangkat.'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _apiKeys.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _apiKeys[index];
                      final keyId = item['id']?.toString() ?? '';
                      final isCurrentDevice = keyId == _currentKeyId;
                      
                      final metadata = item['metadata'] as Map<String, dynamic>? ?? {};
                      var deviceModel = metadata['deviceModel']?.toString() ?? 'Perangkat Tidak Dikenal';
                      if (deviceModel.toLowerCase().contains('sdk_gphone')) {
                        deviceModel = 'Android Emulator';
                      } else {
                        // Capitalize tiap kata
                        deviceModel = deviceModel.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
                      }

                      final platform = metadata['platform']?.toString().toLowerCase() ?? '';
                      
                      final registeredAt = metadata['registeredAt'] != null
                          ? DateTime.tryParse(metadata['registeredAt'])
                          : null;
                      final dateStr = registeredAt != null
                          ? DateFormat('dd MMM yyyy', 'id_ID').format(registeredAt.toLocal())
                          : '-';

                      final lastRequestAt = item['lastRequest'] != null
                          ? DateTime.tryParse(item['lastRequest'])
                          : null;
                      final lastRequestStr = lastRequestAt != null
                          ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(lastRequestAt.toLocal())
                          : 'Belum ada aktivitas';

                      IconData deviceIcon = Icons.smartphone;
                      if (platform.contains('android')) deviceIcon = Icons.android;
                      if (platform.contains('ios')) deviceIcon = Icons.phone_iphone;

                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: isCurrentDevice 
                              ? Border.all(color: AppColors.primary, width: 1.5)
                              : Border.all(color: isDark ? Colors.white12 : Colors.black12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: isCurrentDevice
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : isDark ? Colors.white12 : Colors.grey.shade100,
                            child: Icon(
                              deviceIcon,
                              color: isCurrentDevice ? AppColors.primary : (isDark ? Colors.white70 : Colors.black54),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  deviceModel,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (isCurrentDevice)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Ini',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text('Terdaftar: $dateStr', style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(
                                'Aktivitas Terakhir: $lastRequestStr', 
                                style: TextStyle(
                                  fontSize: 12, 
                                  color: isDark ? Colors.white70 : Colors.black54
                                )
                              ),
                            ],
                          ),
                          trailing: isCurrentDevice
                              ? null // Jangan kasih tombol hapus untuk device saat ini (bisa logout sendiri)
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                  onPressed: () => _deleteKey(keyId),
                                  tooltip: 'Hapus Perangkat',
                                ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
