import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/error_utils.dart';
import '../../../services/auth_service.dart';

class SesiAktifScreen extends StatefulWidget {
  const SesiAktifScreen({super.key});

  @override
  State<SesiAktifScreen> createState() => _SesiAktifScreenState();
}

class _SesiAktifScreenState extends State<SesiAktifScreen> {
  bool _isLoading = true;
  List<dynamic> _sessions = [];
  String? _currentToken;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await AuthService.listSessions();
      
      if (mounted) {
        setState(() {
          _sessions = List.from(sessions);
          // Urutkan berdasarkan updatedAt (aktivitas terakhir) secara descending
          _sessions.sort((a, b) {
            final timeA = DateTime.tryParse(a['updatedAt']?.toString() ?? '') ?? DateTime(2000);
            final timeB = DateTime.tryParse(b['updatedAt']?.toString() ?? '') ?? DateTime(2000);
            return timeB.compareTo(timeA);
          });
          _isLoading = false;
        });
        
        final localToken = await AuthService.getDeviceToken();
        if (localToken != null && mounted) {
          setState(() => _currentToken = localToken);
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

  Future<void> _revokeSession(String token) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Akhiri Sesi?'),
        content: const Text('Sesi login ini akan diakhiri secara paksa (logout).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Akhiri'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await AuthService.revokeSession(token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi berhasil diakhiri')),
        );
        _loadData();
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

  String _formatUserAgent(String userAgent) {
    if (userAgent.contains('Chrome')) return 'Google Chrome';
    if (userAgent.contains('Safari') && !userAgent.contains('Chrome')) return 'Safari';
    if (userAgent.contains('Firefox')) return 'Mozilla Firefox';
    if (userAgent.contains('Edge')) return 'Microsoft Edge';
    if (userAgent.contains('Dart')) return 'Aplikasi Mobile (DigiLH)';
    return userAgent.split(' ').first; // Coba ambil kata pertama jika tidak dikenal
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesi Aktif'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(child: Text('Tidak ada sesi yang aktif.'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sessions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _sessions[index];
                      final token = item['token']?.toString() ?? '';
                      final isCurrentSession = token == _currentToken;
                      
                      final userAgent = item['userAgent']?.toString() ?? 'Unknown Device';
                      final clientName = _formatUserAgent(userAgent);
                      final ipAddress = item['ipAddress']?.toString() ?? 'IP Tidak Diketahui';
                      
                      final createdAt = item['createdAt'] != null
                          ? DateTime.tryParse(item['createdAt'])
                          : null;
                      final dateStr = createdAt != null
                          ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(createdAt.toLocal())
                          : '-';

                      final updatedAt = item['updatedAt'] != null
                          ? DateTime.tryParse(item['updatedAt'])
                          : null;
                      final lastActivityStr = updatedAt != null
                          ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(updatedAt.toLocal())
                          : '-';

                      IconData deviceIcon = Icons.computer;
                      if (userAgent.contains('Dart') || userAgent.contains('Mobile')) {
                        deviceIcon = Icons.smartphone;
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: isCurrentSession 
                              ? Border.all(color: AppColors.primary, width: 1.5)
                              : Border.all(color: isDark ? Colors.white12 : Colors.black12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: isCurrentSession
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : isDark ? Colors.white12 : Colors.grey.shade100,
                            child: Icon(
                              deviceIcon,
                              color: isCurrentSession ? AppColors.primary : (isDark ? Colors.white70 : Colors.black54),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  clientName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (isCurrentSession)
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
                              Text('IP: $ipAddress', style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 2),
                              Text('Login: $dateStr', style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(
                                'Aktivitas: $lastActivityStr', 
                                style: TextStyle(
                                  fontSize: 12, 
                                  color: isDark ? Colors.white70 : Colors.black54
                                )
                              ),
                            ],
                          ),
                          trailing: isCurrentSession
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.exit_to_app, color: AppColors.error),
                                  onPressed: () => _revokeSession(token),
                                  tooltip: 'Akhiri Sesi',
                                ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
