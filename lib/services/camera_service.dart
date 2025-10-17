import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  final ImagePicker _picker = ImagePicker();
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  /// Initialize camera service
  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras!.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
      }
    } catch (e) {
      print('❌ [CameraService] Error initializing camera: $e');
      rethrow;
    }
  }

  /// Get camera controller
  CameraController? get controller => _controller;

  /// Check if camera is available
  bool get isCameraAvailable =>
      _controller != null && _controller!.value.isInitialized;

  /// Take photo using camera
  Future<File?> takePhoto() async {
    try {
      if (!isCameraAvailable) {
        await initialize();
      }

      if (!isCameraAvailable) {
        throw Exception('Camera not available');
      }

      final XFile photo = await _controller!.takePicture();
      return File(photo.path);
    } catch (e) {
      print('❌ [CameraService] Error taking photo: $e');
      rethrow;
    }
  }

  /// Pick photo from gallery
  Future<File?> pickPhotoFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('❌ [CameraService] Error picking photo from gallery: $e');
      rethrow;
    }
  }

  /// Pick photo from camera
  Future<File?> pickPhotoFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('❌ [CameraService] Error picking photo from camera: $e');
      rethrow;
    }
  }

  /// Save photo to app directory
  Future<File> savePhotoToAppDirectory(File photoFile) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName =
          'meter_reading_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(appDir.path, fileName);

      return await photoFile.copy(filePath);
    } catch (e) {
      print('❌ [CameraService] Error saving photo: $e');
      rethrow;
    }
  }

  /// Delete photo file
  Future<void> deletePhoto(File photoFile) async {
    try {
      if (await photoFile.exists()) {
        await photoFile.delete();
      }
    } catch (e) {
      print('❌ [CameraService] Error deleting photo: $e');
    }
  }

  /// Dispose camera controller
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
