import 'package:flutter/material.dart';

class AbsenEmptyState extends StatelessWidget {
  final Color subtextColor;

  const AbsenEmptyState({super.key, required this.subtextColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Belum ada pengajuan absen.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: subtextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan tombol + di bawah untuk mengajukan cuti, sakit, atau dinas luar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: subtextColor),
          ),
        ],
      ),
    );
  }
}
