import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

class ImageStorageService {
  static const String _imagesFolderName = 'maintenance_images';

  /// 앱 전용 Documents 디렉토리 경로 가져오기
  static Future<Directory> _getAppDocumentsDirectory() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory imagesDir = Directory('${appDocDir.path}/$_imagesFolderName');
    
    // 이미지 폴더가 없으면 생성
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    
    return imagesDir;
  }

  /// 이미지를 앱 전용 폴더에 저장하고 경로 반환
  static Future<String> saveImageToAppDirectory(XFile imageFile) async {
    try {
      final Directory imagesDir = await _getAppDocumentsDirectory();
      
      // 고유한 파일명 생성 (타임스탬프 + 랜덤)
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String randomSuffix = (DateTime.now().microsecondsSinceEpoch % 1000).toString();
      final String fileName = 'maintenance_${timestamp}_$randomSuffix.jpg';
      
      final String newPath = '${imagesDir.path}/$fileName';
      
      // 원본 파일을 새 위치로 복사
      final File originalFile = File(imageFile.path);
      final File newFile = await originalFile.copy(newPath);
      
      return newFile.path;
    } catch (e) {
      throw Exception('이미지 저장 중 오류가 발생했습니다: $e');
    }
  }

  /// 여러 이미지를 앱 전용 폴더에 저장하고 경로 리스트 반환
  static Future<List<String>> saveImagesToAppDirectory(List<XFile> imageFiles) async {
    try {
      final List<String> savedPaths = [];
      
      for (final XFile imageFile in imageFiles) {
        final String savedPath = await saveImageToAppDirectory(imageFile);
        savedPaths.add(savedPath);
      }
      
      return savedPaths;
    } catch (e) {
      throw Exception('이미지들 저장 중 오류가 발생했습니다: $e');
    }
  }

  /// 이미지 파일이 존재하는지 확인
  static Future<bool> imageExists(String imagePath) async {
    try {
      final File file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// 이미지 파일 삭제
  static Future<void> deleteImage(String imagePath) async {
    try {
      final File file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('이미지 삭제 중 오류가 발생했습니다: $e');
    }
  }

  /// 여러 이미지 파일 삭제
  static Future<void> deleteImages(List<String> imagePaths) async {
    try {
      for (final String imagePath in imagePaths) {
        await deleteImage(imagePath);
      }
    } catch (e) {
      throw Exception('이미지들 삭제 중 오류가 발생했습니다: $e');
    }
  }

  /// 앱 전용 이미지 폴더의 모든 이미지 삭제
  static Future<void> clearAllImages() async {
    try {
      final Directory imagesDir = await _getAppDocumentsDirectory();
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
        await imagesDir.create(recursive: true);
      }
    } catch (e) {
      throw Exception('모든 이미지 삭제 중 오류가 발생했습니다: $e');
    }
  }

  /// 앱 전용 이미지 폴더 크기 확인 (바이트)
  static Future<int> getImagesFolderSize() async {
    try {
      final Directory imagesDir = await _getAppDocumentsDirectory();
      if (!await imagesDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final FileSystemEntity entity in imagesDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// 이미지 파일 크기 확인 (바이트)
  static Future<int> getImageSize(String imagePath) async {
    try {
      final File file = File(imagePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
