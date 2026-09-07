/// Web-safe stub for image_picker used when building Flutter Web.
///
/// Provides minimal types and APIs to satisfy analyzer and prevent web
/// compilation failures. At runtime these methods throw UnsupportedError to
/// avoid accidental use in unsupported platforms.

class UnsupportedPlatformError extends UnsupportedError {
  UnsupportedPlatformError([String message = 'This API is not supported on this platform.']) : super(message);
}

enum ImageSource { camera, gallery }

enum FilePickerFileType { image, video, media, custom }

class XFile {
  final String path;
  XFile(this.path);

  /// Not supported on web stub
  factory XFile.fromBytes(List<int> bytes, {required String name, required String mimeType}) {
    throw UnsupportedPlatformError();
  }

  int get lengthInBytes => throw UnsupportedPlatformError();
  String get name => throw UnsupportedPlatformError();
  String get mimeType => throw UnsupportedPlatformError();
}

class ImagePicker {
  ImagePicker._();

  static final ImagePicker instance = ImagePicker._();

  Future<XFile?> pickImage({
    ImageSource? source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    throw UnsupportedPlatformError();
  }

  Future<XFile?> pickVideo({
    ImageSource? source,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
    Duration? maxDuration,
  }) async {
    throw UnsupportedPlatformError();
  }

  Future<List<XFile>?> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    throw UnsupportedPlatformError();
  }

  Future<List<XFile>?> pickFiles({
    ImageSource? source,
    FilePickerFileType type = FilePickerFileType.image,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    throw UnsupportedPlatformError();
  }
}
