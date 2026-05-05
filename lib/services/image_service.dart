import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<List<String>> pickAndUploadMultipleImages(String orderId) async {
    try {
      final List<String> urls = [];

      if (kIsWeb) {
        // On web, pick one at a time in a loop
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
          maxWidth: 1024,
        );
        if (image == null) return [];
        final url = await _uploadXFile(
            image, orderId, DateTime.now().millisecondsSinceEpoch);
        if (url != null) urls.add(url);
      } else {
        // On mobile, pick multiple
        final List<XFile> images = await _picker.pickMultiImage(
          imageQuality: 70,
          maxWidth: 1024,
        );
        if (images.isEmpty) return [];
        for (int i = 0; i < images.length; i++) {
          final url = await _uploadXFile(images[i], orderId, i);
          if (url != null) urls.add(url);
        }
      }
      return urls;
    } catch (e) {
      return [];
    }
  }

  Future<String?> takeAndUploadPhoto(String orderId) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1024,
      );
      if (image == null) return null;
      return await _uploadXFile(
          image, orderId, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      return null;
    }
  }

  Future<String?> _uploadXFile(
      XFile file, String orderId, int index) async {
    try {
      final fileName =
          'orders/$orderId/${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
      final ref = _storage.ref().child(fileName);
      final bytes = await file.readAsBytes();
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await ref.putData(bytes, metadata);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // ignore
    }
  }
}