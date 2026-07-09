import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PhotoPreviewScreen extends StatelessWidget {
  final String? imagePath;

  const PhotoPreviewScreen({super.key, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Foto Kerusakan',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
        ),
      ),
      body: Center(
        child: imagePath != null
            ? (imagePath!.startsWith('http')
                ? InteractiveViewer(
                    child: Image.network(
                      imagePath!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    ),
                  )
                : File(imagePath!).existsSync()
                    ? InteractiveViewer(
                        child: Image.file(
                          File(imagePath!),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        ),
                      )
                    : _placeholder())
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.image_outlined, color: Colors.white54, size: 64),
        const SizedBox(height: 12),
        Text(
          'Foto tidak tersedia',
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
        ),
      ],
    );
  }
}
