import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:maintenance_note/models/maintenance_record.dart';

class MaintenanceDetailBottomSheet extends StatelessWidget {
  final MaintenanceRecord record;

  const MaintenanceDetailBottomSheet({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // 핸들 바
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 헤더
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  record.vehicleType.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${record.vehicleType.displayName} 정비 상세',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('yyyy년 MM월 dd일').format(record.maintenanceDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // 내용
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 정비 내용
                  _buildDetailSection(
                    '정비 내용',
                    record.maintenanceContent,
                    Icons.build,
                    Colors.blue,
                  ),
                  const SizedBox(height: 20),
                  
                  // 비용과 마일리지
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          '정비 비용',
                          '${NumberFormat('#,###').format(record.cost)}원',
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          '마일리지',
                          '${NumberFormat('#,###').format(record.currentMileage)}km',
                          Icons.speed,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // 추후 정비
                  if (record.futureMaintenance.isNotEmpty) ...[
                    _buildDetailSection(
                      '추후 필요한 정비',
                      record.futureMaintenance,
                      Icons.schedule,
                      Colors.amber,
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // 정비 사진
                  if (record.imagePaths.isNotEmpty) ...[
                    _buildPhotoSection(context),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo, color: Colors.purple, size: 20),
            const SizedBox(width: 8),
            Text(
              '정비 사진 (${record.imagePaths.length}장)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: record.imagePaths.length,
            itemBuilder: (context, index) {
              return _buildImageThumbnail(context, record.imagePaths[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(BuildContext context, String imagePath) {
    return GestureDetector(
      onTap: () => _showImageDialog(context, imagePath),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 120,
            height: 120,
            color: Colors.grey.shade100,
            child: FutureBuilder<bool>(
              future: _checkImageExists(imagePath),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                
                if (snapshot.hasError || !snapshot.data!) {
                  return _buildImageErrorWidget();
                }
                
                return Image.file(
                  File(imagePath),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildImageErrorWidget();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageErrorWidget() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 32,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 4),
          Text(
            '사진을\n불러올 수 없어요 😢',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkImageExists(String imagePath) async {
    try {
      final file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  void _showImageDialog(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            color: Colors.black87,
            child: Center(
              child: GestureDetector(
                onTap: () {}, // 이미지 클릭 시 닫히지 않도록
                child: FutureBuilder<bool>(
                  future: _checkImageExists(imagePath),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    }
                    
                    if (snapshot.hasError || !snapshot.data!) {
                      return Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              size: 64,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '사진을 불러올 수 없어요 😢',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '파일이 삭제되었거나\n이동되었을 수 있습니다',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return InteractiveViewer(
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  size: 64,
                                  color: Colors.white70,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  '사진을 불러올 수 없어요 😢',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '파일이 손상되었을 수 있습니다',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
