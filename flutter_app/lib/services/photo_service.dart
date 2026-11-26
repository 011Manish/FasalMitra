const maxPhotoBytes = 5 * 1024 * 1024;

class PhotoTooLarge implements Exception {
  const PhotoTooLarge(this.bytes);
  final int bytes;
  @override
  String toString() =>
      'Photo is ${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB; max is 5 MB.';
}
