import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maintenance_note/models/maintenance_record.dart';
import 'package:maintenance_note/services/maintenance_service.dart';
import 'package:maintenance_note/screens/maintenance_detail_bottom_sheet.dart';

class MaintenanceListScreen extends StatefulWidget {
  const MaintenanceListScreen({super.key});

  @override
  State<MaintenanceListScreen> createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends State<MaintenanceListScreen> {
  final MaintenanceService _maintenanceService = MaintenanceService();
  List<MaintenanceRecord> _records = [];
  bool _isLoading = true;
  VehicleType? _selectedVehicleType;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final records = await _maintenanceService.getAllMaintenanceRecords();
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('기록을 불러오는 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  List<MaintenanceRecord> get _filteredRecords {
    if (_selectedVehicleType == null) {
      return _records;
    }
    return _records.where((record) => record.vehicleType == _selectedVehicleType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          '정비 기록',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        centerTitle: true,
        actions: [
          // 필터 버튼
          PopupMenuButton<VehicleType?>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (VehicleType? type) {
              setState(() {
                _selectedVehicleType = type;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<VehicleType?>(
                value: null,
                child: Text('전체'),
              ),
              const PopupMenuItem<VehicleType?>(
                value: VehicleType.car,
                child: Text('🚗 자동차'),
              ),
              const PopupMenuItem<VehicleType?>(
                value: VehicleType.bike,
                child: Text('🏍️ 바이크'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredRecords.isEmpty
              ? _buildEmptyState()
              : _buildRecordsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build_circle_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            '정비 기록이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '첫 번째 정비 일지를 작성해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    return Column(
      children: [
        // 필터 표시
        if (_selectedVehicleType != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _selectedVehicleType == VehicleType.car 
                  ? Colors.green.shade50 
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedVehicleType == VehicleType.car 
                    ? Colors.green.shade200 
                    : Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                Text(
                  _selectedVehicleType!.icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_selectedVehicleType!.displayName} 기록만 표시',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _selectedVehicleType == VehicleType.car 
                        ? Colors.green.shade700 
                        : Colors.orange.shade700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedVehicleType = null;
                    });
                  },
                  child: const Text('전체 보기'),
                ),
              ],
            ),
          ),
        
        // 기록 목록
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredRecords.length,
            itemBuilder: (context, index) {
              final record = _filteredRecords[index];
              return _buildRecordCard(record);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(MaintenanceRecord record) {
    return GestureDetector(
      onTap: () => _showMaintenanceDetail(record),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 (차량 타입, 날짜)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      record.vehicleType.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      record.vehicleType.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('MM/dd').format(record.maintenanceDate),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 정비 내용
            Text(
              record.maintenanceContent,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            // 비용과 마일리지
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${NumberFormat('#,###').format(record.cost)}원',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${NumberFormat('#,###').format(record.currentMileage)}km',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            // 추후 정비 내용
            if (record.futureMaintenance.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '추후 정비',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.futureMaintenance,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // 사진 개수 표시
            if (record.imagePaths.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.photo, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${record.imagePaths.length}장',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ));
  }

  void _showMaintenanceDetail(MaintenanceRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MaintenanceDetailBottomSheet(record: record),
    );
  }
}
