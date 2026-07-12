import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/pegawai.dart';

class ProfilHeaderCard extends StatelessWidget {
  final Pegawai? pegawai;
  final VoidCallback? onTapEdit;
  final bool isUploading;

  const ProfilHeaderCard({
    super.key,
    required this.pegawai,
    this.onTapEdit,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white.withValues(alpha: 0.1) 
                    : Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                image: (pegawai?.localFotoPath != null)
                    ? DecorationImage(
                        image: FileImage(File(pegawai!.localFotoPath!)),
                        fit: BoxFit.contain, // Prevent cropping
                      )
                    : null,
              ),
              child: (pegawai?.localFotoPath == null)
                  ? Center(
                      child: Text(
                        pegawai?.nama.isNotEmpty == true
                            ? pegawai!.nama[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white 
                              : Colors.black87,
                        ),
                      ),
                    )
                  : null,
            ),
            if (isUploading)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            if (!isUploading && onTapEdit != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onTapEdit,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
