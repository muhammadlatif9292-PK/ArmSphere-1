/// Stub for image_picker package.
///
/// Native file/camera picker is web-incompatible. On web, throw
/// NotImplementedError to prevent runtime crashes.

import 'dart:io' if (dart.library.html) 'dart:ui' as ui;

class _ImagePickerStub {
  static throwNotImplementedError() {
    throw NotImplementedError(
      'Image picker is not supported in web build. '
      'Consider using file input dialog or URL-based image upload for web. '
      'See: https://docs.flutter.dev/cookbook/plugins/picking-images',
    );
  }
}

class ImagePicker {
  ImagePicker._();

  // Always throw on web
  Future<XFile?> pickImage({
    ImageSource? source,
    double maxWidth,
    double maxHeight,
    int imageQuality,
  }) async {
    throwNotImplementedError();
  }

  // Always throw on web
  Future<XFile?> pickVideo({
    ImageSource? source,
    int maxWidth,
    int maxHeight,
    int imageQuality,
    Duration maxDuration,
  }) async {
    throwNotImplementedError();
  }

  // Always throw on web
  Future<XFile?> pickMultiImage({
    double maxWidth,
    double maxHeight,
    int imageQuality,
  }) async {
    throwNotImplementedError();
  }

  // Always throw on web
  Future<XFile?> pickFiles({
    ImageSource? source,
    FilePickerFileType type = FilePickerFileType.image,
    int maxWidth,
    int maxHeight,
    int imageQuality,
  }) async {
    throwNotImplementedError();
  }
}

enum ImageSource { camera, gallery }

// Stub XFile for return type compatibility
class XFile {
  XFile(this.path);

  factory XFile.fromBytes(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) {
    throwNotImplementedError();
  }

  String get path;
  int get lengthInBytes;
  String get name;
  String get mimeType;
}

enum FilePickerFileType { image, video, media, custom }
