import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/providers.dart';
import 'add_metadata_screen.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isLoading = false;
  FlashMode _flashMode = FlashMode.off;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = ref.read(camerasProvider);
      if (cameras.isEmpty) {
        // No cameras available
        return;
      }

      final camera = cameras[_selectedCameraIndex];
      // Dispose old controller if exists
      if (_controller != null) {
        await _controller!.dispose();
      }

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Camera error: $e')));
      }
    }
  }

  Future<void> _toggleCamera() async {
    final cameras = ref.read(camerasProvider);
    if (cameras.length < 2) return;

    setState(() => _isCameraInitialized = false);
    _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras.length;
    await _initializeCamera();
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    FlashMode nextMode = _flashMode == FlashMode.off
        ? FlashMode.torch
        : FlashMode.off;

    try {
      await _controller!.setFlashMode(nextMode);
      setState(() => _flashMode = nextMode);
    } catch (_) {}
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_isCameraInitialized || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      // 1. Capture
      final XFile tempFile = await _controller!.takePicture();

      // Copy to permanent app directory
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/geotag_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final fileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final permanentPath = '${imagesDir.path}/$fileName';
      await File(tempFile.path).copy(permanentPath);
      final file = XFile(permanentPath);

      // 2. Fetch Location & Address
      final locService = ref.read(locationServiceProvider);
      // Wait for multiple things if needed, but sequential is safer for reliability

      // Get location with timeout in case GPS is stuck
      Position? position;
      try {
        position = await locService.getCurrentPosition();
      } catch (e) {
        // location fetch failed, proceed with empty
      }

      String address = "Unknown Location";
      double lat = 0.0;
      double lng = 0.0;
      double accuracy = 0.0;
      double altitude = 0.0;

      if (position != null) {
        lat = position.latitude;
        lng = position.longitude;
        accuracy = position.accuracy;
        altitude = position.altitude;
        // Fetch address only if we have location
        address = await locService.getAddressFromCoordinates(lat, lng);
      } else {
        // Handle failed location
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not fetch location. Using (0,0).'),
            ),
          );
        }
      }

      if (!mounted) return;

      // 3. Navigate
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddMetadataScreen(
            imagePath: file.path,
            latitude: lat,
            longitude: lng,
            accuracy: accuracy,
            altitude: altitude,
            initialAddress: address,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),
          // Overlay controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: const BackButton(color: Colors.white),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: IconButton(
              onPressed: _toggleFlash,
              icon: Icon(
                _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
                color: Colors.white,
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 150,
              padding: const EdgeInsets.only(bottom: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 40), // spacer

                  FloatingActionButton.large(
                    heroTag: 'captureBtn',
                    onPressed: _takePicture,
                    backgroundColor: Colors.white,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Icon(
                            Icons.circle,
                            size: 60,
                            color: Colors.black,
                          ), // Shutter button look
                  ),

                  IconButton(
                    onPressed: _toggleCamera,
                    icon: const Icon(
                      Icons.cameraswitch,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
