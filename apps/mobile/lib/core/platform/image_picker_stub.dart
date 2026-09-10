/// Stub for image_picker package.
///
/// Native file/camera picker is web-incompatible. On web, throw
/// NotImplementedError to prevent runtime crashes.
library;

import 'dart:typed_data';

Never throwNotImplementedError() {
  throw UnsupportedError(
    'Image picker is not supported in web build. '
    'Use a web file input or URL-based image upload instead.',
  );
}

class ImagePicker {
  ImagePicker._();

  // Always throw on web
  Future<XFile?> pickImage({
    ImageSource? source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    throwNotImplementedError();
  }

  // Always throw on web
  Future<XFile?> pickVideo({
    ImageSource? source,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
    Duration? maxDuration,
  }) async {
    throwNotImplementedError();
  }

  // Always throw on web
  Future<XFile?> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    throwNotImplementedError();
  }

  // Always throw on web
  Future<XFile?> pickFiles({
    ImageSource? source,
    FilePickerFileType type = FilePickerFileType.image,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    throwNotImplementedError();
  }
}

enum ImageSource { camera, gallery }

// Stub XFile for return type compatibility
class XFile {
  XFile(this.path, {String? name, String? mimeType})
      : _name = name ?? path.split('/').last,
        _mimeType = mimeType ?? 'application/octet-stream';

  final String path;
  final String _name;
  final String _mimeType;

  factory XFile.fromBytes(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) {
    throwNotImplementedError();
  }

  int get lengthInBytes => throwNotImplementedError();
  String get name => _name;
  String get mimeType => _mimeType;
}

enum FilePickerFileType { image, video, media, custom }
