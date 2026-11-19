import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../../core/constants/app_constants.dart';

class FaceMissionView extends StatefulWidget {
  final VoidCallback onCompleted;
  final VoidCallback onEmergencyOverride;

  const FaceMissionView({
    super.key,
    required this.onCompleted,
    required this.onEmergencyOverride,
  });

  @override
  State<FaceMissionView> createState() => _FaceMissionViewState();
}

class _FaceMissionViewState extends State<FaceMissionView> {
  CameraController? _cameraController;
  late final FaceDetector _faceDetector;
  bool _isProcessing = false;
  bool _isCameraReady = false;

  // Status Deteksi Mata
  bool _eyesOpenDetected = false;
  double _eyeOpenHoldProgress = 0.0;
  Timer? _holdTimer;
  int _consecutiveOpenTicks = 0; // 1 tick = 100ms. 30 ticks = 3 detik
  static const int _targetTicks = AppConstants.faceHoldSeconds * 10;

  double? _previousBrightness;

  @override
  void initState() {
    super.initState();
    _initDetector();
    _forceScreenFlash();
    _initCamera();
  }

  void _initDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true, // Untuk deteksi mata terbuka
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.25,
      ),
    );
  }

  Future<void> _forceScreenFlash() async {
    try {
      _previousBrightness = await ScreenBrightness.instance.current;
      await ScreenBrightness.instance.setScreenBrightness(1.0); // Kecerahan 100%
    } catch (e) {
      debugPrint('Error forcing screen brightness: $e');
    }
  }

  Future<void> _restoreScreenBrightness() async {
    try {
      if (_previousBrightness != null) {
        await ScreenBrightness.instance.setScreenBrightness(_previousBrightness!);
      } else {
        await ScreenBrightness.instance.resetScreenBrightness();
      }
    } catch (e) {
      debugPrint('Error restoring brightness: $e');
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      // Pilih kamera depan
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraReady = true;
      });

      _startImageStream();
      _startHoldProgressTicker();
    } catch (e) {
      debugPrint('Error init camera: $e');
    }
  }

  void _startImageStream() {
    _cameraController?.startImageStream((CameraImage image) async {
      if (_isProcessing) return;
      _isProcessing = true;

      try {
        final inputImage = _convertCameraImageToInputImage(image);
        if (inputImage == null) {
          _isProcessing = false;
          return;
        }

        final faces = await _faceDetector.processImage(inputImage);
        if (faces.isNotEmpty) {
          final face = faces.first;
          final leftEyeOpen = face.leftEyeOpenProbability ?? 0.0;
          final rightEyeOpen = face.rightEyeOpenProbability ?? 0.0;

          // Ambang batas: kedua mata harus terbuka lebar (> 0.75)
          final bool bothEyesOpen = leftEyeOpen >= 0.75 && rightEyeOpen >= 0.75;

          if (mounted) {
            setState(() {
              _eyesOpenDetected = bothEyesOpen;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _eyesOpenDetected = false;
            });
          }
        }
      } catch (e) {
        debugPrint('Error processing face image: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }

  void _startHoldProgressTicker() {
    // Ticker setiap 100ms
    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_eyesOpenDetected) {
        _consecutiveOpenTicks++;
      } else {
        // Jika mata terpejam, kurangi progres secara cepat
        if (_consecutiveOpenTicks > 0) {
          _consecutiveOpenTicks = (_consecutiveOpenTicks - 2).clamp(0, _targetTicks);
        }
      }

      final progress = (_consecutiveOpenTicks / _targetTicks).clamp(0.0, 1.0);
      setState(() {
        _eyeOpenHoldProgress = progress;
      });

      // Target 3 detik mata terbuka tercapai!
      if (_consecutiveOpenTicks >= _targetTicks) {
        timer.cancel();
        _onFaceMissionSuccess();
      }
    });
  }

  void _onFaceMissionSuccess() {
    widget.onCompleted();
  }

  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    if (_cameraController == null) return null;
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
    _restoreScreenBrightness();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Frame Putih Terang Sebagai "Screen Flash" Penerang Wajah
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 14),
      ),
      child: Container(
        color: const Color(0xFF0F1126),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blueAccent),
                  ),
                  child: const Text(
                    'MISI 2: SCAN WAJAH (MATA TERBUKA)',
                    style: TextStyle(
                      color: Colors.lightBlueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onEmergencyOverride,
                  child: const Text(
                    'Kamera Gagal?',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Petunjuk
            Text(
              _eyesOpenDetected
                  ? 'Pertahankan mata terbuka! (${(_eyeOpenHoldProgress * AppConstants.faceHoldSeconds).toStringAsFixed(1)}s)'
                  : 'Buka kedua mata Anda lebar-lebar ke arah kamera!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _eyesOpenDetected ? Colors.greenAccent : Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Progress Bar Penahan Mata 3 Detik
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _eyeOpenHoldProgress,
                minHeight: 12,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _eyeOpenHoldProgress > 0.8 ? Colors.greenAccent : Colors.amberAccent,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Preview Kamera Depan dengan Frame Bulat/Oval
            Expanded(
              child: Center(
                child: _isCameraReady && _cameraController != null
                    ? Container(
                        width: 250,
                        height: 310,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _eyesOpenDetected ? Colors.greenAccent : Colors.white30,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _eyesOpenDetected
                                  ? Colors.greenAccent.withOpacity(0.4)
                                  : Colors.white.withOpacity(0.2),
                              blurRadius: 16,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CameraPreview(_cameraController!),
                        ),
                      )
                    : const CircularProgressIndicator(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),

            // Status Ikon Deteksi
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _eyesOpenDetected ? Icons.visibility : Icons.visibility_off,
                  color: _eyesOpenDetected ? Colors.greenAccent : Colors.orangeAccent,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  _eyesOpenDetected ? 'Mata Terbuka Terdeteksi' : 'Mata Belum Terbuka Penuh',
                  style: TextStyle(
                    color: _eyesOpenDetected ? Colors.greenAccent : Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
