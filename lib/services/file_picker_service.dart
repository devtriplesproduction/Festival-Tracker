import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class FilePickerService {
  /// Picks a file (image or PDF).
  /// Returns the XFile object.
  Future<XFile?> pickFile() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: kIsWeb, // Pre-load bytes on web
    );
    
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    
    if (kIsWeb) {
      if (file.bytes == null) return null;
      return XFile.fromData(file.bytes!, name: file.name, length: file.size);
    } else {
      if (file.path == null) return null;
      return XFile(file.path!);
    }
  }

  // Fallback for picking and compressing image for compatibility, though we just pick file now.
  Future<XFile?> pickAndCompressImage() async {
    return await pickFile();
  }
}
