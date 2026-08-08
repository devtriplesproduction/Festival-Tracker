import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../models/assignment.dart';
import '../models/app_user.dart';
import 'file_picker_service.dart';

class UploadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FilePickerService _filePickerService = FilePickerService();
  
  // Cloudinary credentials
  static const String _cloudinaryCloudName = 'uqrlcr3w';
  static const String _cloudinaryUploadPreset = 'uqrlcr3w';

  /// Starts the upload process: picks file, uploads to Firebase Storage,
  /// and updates the assignment document in Firestore.
  Future<void> startUpload({
    required Assignment assignment,
    required String festivalName,
    required String festivalYear,
    required String clientName,
    required AppUser currentUser,
    required Function(double) onProgress,
  }) async {
    final xFile = await _filePickerService.pickFile();
    
    if (xFile == null) {
      throw Exception('No file selected.');
    }

    final String fileName = xFile.name;
    final String imagePath = xFile.path;

    // 1. Update Firestore to indicate uploading has started
    await _firestore.collection('assignments').doc(assignment.id).update({
      'posterUploadStatus': 'uploading',
      'posterPreviewPath': imagePath, // Show local preview immediately if image
    });

    try {
      onProgress(0.1);

      List<int> bytes = await xFile.readAsBytes();

      onProgress(0.3);

      final ext = p.extension(fileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${assignment.id}_$timestamp$ext';

      // 2. Upload to Cloudinary
      // We use /auto/upload to ensure it automatically handles both Images and PDFs flawlessly
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/auto/upload');
      final request = http.MultipartRequest('POST', uri);
      
      request.fields['upload_preset'] = _cloudinaryUploadPreset;
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file', 
          bytes,
          filename: uniqueFileName,
        )
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Cloudinary upload failed: ${response.body}');
      }

      final responseData = json.decode(response.body);
      final String downloadUrl = responseData['secure_url'];

      onProgress(0.9);

      // 3. Update Firestore with URL
      await _firestore.collection('assignments').doc(assignment.id).update({
        'posterUrl': downloadUrl,
        'posterFileName': uniqueFileName,
        'posterFileSize': bytes.length,
        'posterUploadedBy': currentUser.displayName,
        'posterUploadedAt': FieldValue.serverTimestamp(),
        'posterUploadStatus': 'success',
      });
      
      onProgress(1.0);

    } catch (e) {
      // Revert status on failure
      await _firestore.collection('assignments').doc(assignment.id).update({
        'posterUploadStatus': 'failed',
        'posterUploadError': 'Upload failed: $e',
      });
      throw Exception('Failed to upload to Cloudinary: $e');
    }
  }

  /// Removes the uploaded poster from the assignment
  Future<void> deletePoster(String assignmentId) async {
    await _firestore.collection('assignments').doc(assignmentId).update({
      'posterUrl': FieldValue.delete(),
      'posterFileName': FieldValue.delete(),
      'posterFileSize': FieldValue.delete(),
      'posterUploadedBy': FieldValue.delete(),
      'posterUploadedAt': FieldValue.delete(),
      'posterUploadStatus': FieldValue.delete(),
      'posterPreviewPath': FieldValue.delete(),
    });
  }

  /// Checks if connected 
  Future<bool> isDriveConnected() async {
    return true; 
  }
}
