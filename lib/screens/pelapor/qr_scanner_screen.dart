import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_theme.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // ── Gradient Header ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.headerEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Scan QR Ruangan',
                        style: GoogleFonts.manrope(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ── Camera + Overlay ──
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bodyW = constraints.maxWidth;
                final bodyH = constraints.maxHeight;
                const scanSize = 250.0;
                final scanLeft = (bodyW - scanSize) / 2;
                const scanTop = 70.0;

                return Stack(
                  children: [
                    // Camera preview
                    MobileScanner(
                      controller: cameraController,
                      onDetect: (capture) {
                        if (_isScanned) return;
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          if (barcode.rawValue != null) {
                            _isScanned = true;
                            final String code = barcode.rawValue!;
                            Navigator.pop(context, code);
                            break;
                          }
                        }
                      },
                    ),
                    // Dark overlay with cutout
                    CustomPaint(
                      painter: _ScannerOverlayPainter(
                        scanRect: Rect.fromLTWH(scanLeft, scanTop, scanSize, scanSize),
                      ),
                      size: Size(bodyW, bodyH),
                    ),
                    // Instruction text
                    Positioned(
                      left: 0,
                      right: 0,
                      top: scanTop - 36,
                      child: Text(
                        'Arahkan kamera ke QR Code',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    // ── Corner brackets ──
                    _buildCorner(left: scanLeft - 3, top: scanTop - 3, topSide: true, leftSide: true),
                    _buildCorner(
                      left: scanLeft + scanSize - 25,
                      top: scanTop - 3,
                      topSide: true,
                      leftSide: false,
                    ),
                    _buildCorner(
                      left: scanLeft - 3,
                      top: scanTop + scanSize - 25,
                      topSide: false,
                      leftSide: true,
                    ),
                    _buildCorner(
                      left: scanLeft + scanSize - 25,
                      top: scanTop + scanSize - 25,
                      topSide: false,
                      leftSide: false,
                    ),
                    // ── Torch + Camera switch ──
                    Positioned(
                      left: 0,
                      right: 0,
                      top: scanTop + scanSize + 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ControlButton(
                            child: ValueListenableBuilder(
                              valueListenable: cameraController,
                              builder: (context, state, child) {
                                final isOn = state.torchState == TorchState.on;
                                return Icon(
                                  isOn ? Icons.flash_on : Icons.flash_off,
                                  color: isOn ? AppColors.amber : AppColors.primary,
                                  size: 26,
                                );
                              },
                            ),
                            onTap: () => cameraController.toggleTorch(),
                          ),
                          const SizedBox(width: 60),
                          _ControlButton(
                            child: const Icon(Icons.cameraswitch, color: AppColors.primary, size: 26),
                            onTap: () => cameraController.switchCamera(),
                          ),
                        ],
                      ),
                    ),
                    // ── Gradient button at bottom ──
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 40,
                      child: _buildGradientButton(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({
    required double left,
    required double top,
    required bool topSide,
    required bool leftSide,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border(
            top: topSide ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            bottom: !topSide ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            left: leftSide ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            right: !leftSide ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: topSide && leftSide ? const Radius.circular(6) : Radius.zero,
            topRight: topSide && !leftSide ? const Radius.circular(6) : Radius.zero,
            bottomLeft: !topSide && leftSide ? const Radius.circular(6) : Radius.zero,
            bottomRight: !topSide && !leftSide ? const Radius.circular(6) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.buttonTop, AppColors.primary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity( 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              // Scanner already running; button present for visual consistency
            },
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Scan QR Lokasi',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanRect;
  _ScannerOverlayPainter({required this.scanRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity( 0.45);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(scanRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanRect != scanRect;
  }
}

class _ControlButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _ControlButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryLight.withOpacity( 0.7),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            width: 28,
            height: 28,
            child: child,
          ),
        ),
      ),
    );
  }
}
