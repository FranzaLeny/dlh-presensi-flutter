import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void showAttachmentPicker({
  required BuildContext context,
  required ImagePicker imagePicker,
  required Function(String path, String name, String mimeType) onFilePicked,
  required Function(String error) onError,
}) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: const Text('Ambil Foto Kamera'),
            onTap: () async {
              Navigator.pop(ctx);
              await _pickImage(imagePicker, ImageSource.camera, onFilePicked, onError);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Pilih Gambar Galeri'),
            onTap: () async {
              Navigator.pop(ctx);
              await _pickImage(imagePicker, ImageSource.gallery, onFilePicked, onError);
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_rounded),
            title: const Text('Pilih File PDF'),
            onTap: () async {
              Navigator.pop(ctx);
              await _pickPdf(onFilePicked, onError);
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _pickImage(
  ImagePicker picker,
  ImageSource source,
  Function(String path, String name, String mimeType) onFilePicked,
  Function(String error) onError,
) async {
  try {
    final file = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (file != null) {
      onFilePicked(file.path, file.name, 'image/jpeg');
    }
  } catch (e) {
    onError('Gagal mengambil gambar: $e');
  }
}

Future<void> _pickPdf(
  Function(String path, String name, String mimeType) onFilePicked,
  Function(String error) onError,
) async {
  try {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      onFilePicked(
        result.files.single.path!,
        result.files.single.name,
        'application/pdf',
      );
    }
  } catch (e) {
    onError('Gagal memilih file PDF: $e');
  }
}
