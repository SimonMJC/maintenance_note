import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:maintenance_note/models/maintenance_record.dart';
import 'package:maintenance_note/services/maintenance_service.dart';

class MaintenanceFormScreen extends StatefulWidget {
  final VehicleType vehicleType;

  const MaintenanceFormScreen({
    super.key,
    required this.vehicleType,
  });

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _maintenanceContentController = TextEditingController();
  final _costController = TextEditingController();
  final _futureMaintenanceController = TextEditingController();
  final _mileageController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  final MaintenanceService _maintenanceService = MaintenanceService();

  @override
  void dispose() {
    _maintenanceContentController.dispose();
    _costController.dispose();
    _futureMaintenanceController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _saveMaintenanceRecord() async {
    if (_formKey.currentState!.validate()) {
      try {
        final record = MaintenanceRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          maintenanceDate: _selectedDate,
          maintenanceContent: _maintenanceContentController.text,
          cost: double.parse(_costController.text),
          futureMaintenance: _futureMaintenanceController.text,
          currentMileage: int.parse(_mileageController.text),
          imagePaths: _selectedImages.map((image) => image.path).toList(),
          vehicleType: widget.vehicleType,
        );

        await _maintenanceService.saveMaintenanceRecord(record);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('정비 일지가 저장되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('저장 중 오류가 발생했습니다: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          '${widget.vehicleType.displayName} 정비 일지',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: widget.vehicleType == VehicleType.car 
            ? Colors.green.shade600 
            : Colors.orange.shade600,
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 정비 날짜
              _buildSectionTitle('정비 날짜'),
              _buildDateSelector(),
              const SizedBox(height: 20),

              // 정비 내용
              _buildSectionTitle('정비 내용'),
              _buildTextFormField(
                controller: _maintenanceContentController,
                hintText: '예: 엔진오일 교체, 타이어 교체 등',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '정비 내용을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 정비 비용
              _buildSectionTitle('정비 비용 (원)'),
              _buildTextFormField(
                controller: _costController,
                hintText: '예: 50000',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '정비 비용을 입력해주세요';
                  }
                  if (double.tryParse(value) == null) {
                    return '올바른 숫자를 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 현재 마일리지
              _buildSectionTitle('현재 마일리지 (km)'),
              _buildTextFormField(
                controller: _mileageController,
                hintText: '예: 50000',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '현재 마일리지를 입력해주세요';
                  }
                  if (int.tryParse(value) == null) {
                    return '올바른 숫자를 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 추후 필요한 정비
              _buildSectionTitle('추후 필요한 정비'),
              _buildTextFormField(
                controller: _futureMaintenanceController,
                hintText: '예: 다음 정비 시 브레이크 패드 교체 예정',
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // 정비 사진
              _buildSectionTitle('정비 사진'),
              _buildImageSection(),
              const SizedBox(height: 30),

              // 저장 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveMaintenanceRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.vehicleType == VehicleType.car 
                        ? Colors.green.shade600 
                        : Colors.orange.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    '정비 일지 저장',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: () => _selectDate(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
              style: const TextStyle(fontSize: 16),
            ),
            Icon(Icons.calendar_today, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.vehicleType == VehicleType.car 
                ? Colors.green.shade600 
                : Colors.orange.shade600,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        // 이미지 선택 버튼
        Container(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.camera_alt),
            label: const Text('사진 추가'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                color: widget.vehicleType == VehicleType.car 
                    ? Colors.green.shade600 
                    : Colors.orange.shade600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        
        // 선택된 이미지들
        if (_selectedImages.isNotEmpty)
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedImages[index].path),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
