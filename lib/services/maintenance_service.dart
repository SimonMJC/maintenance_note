import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maintenance_note/models/maintenance_record.dart';

class MaintenanceService {
  static const String _recordsKey = 'maintenance_records';

  // 정비 기록 저장
  Future<void> saveMaintenanceRecord(MaintenanceRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingRecords = await getAllMaintenanceRecords();
      
      // 기존 기록에 새 기록 추가
      existingRecords.add(record);
      
      // 날짜순으로 정렬 (최신순)
      existingRecords.sort((a, b) => b.maintenanceDate.compareTo(a.maintenanceDate));
      
      // JSON으로 변환하여 저장
      final recordsJson = existingRecords.map((record) => record.toJson()).toList();
      await prefs.setString(_recordsKey, jsonEncode(recordsJson));
    } catch (e) {
      throw Exception('정비 기록 저장 중 오류가 발생했습니다: $e');
    }
  }

  // 모든 정비 기록 조회
  Future<List<MaintenanceRecord>> getAllMaintenanceRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordsString = prefs.getString(_recordsKey);
      
      if (recordsString == null || recordsString.isEmpty) {
        return [];
      }
      
      final List<dynamic> recordsJson = jsonDecode(recordsString);
      return recordsJson.map((json) => MaintenanceRecord.fromJson(json)).toList();
    } catch (e) {
      throw Exception('정비 기록 조회 중 오류가 발생했습니다: $e');
    }
  }

  // 특정 차량 타입의 정비 기록 조회
  Future<List<MaintenanceRecord>> getMaintenanceRecordsByVehicleType(VehicleType vehicleType) async {
    try {
      final allRecords = await getAllMaintenanceRecords();
      return allRecords.where((record) => record.vehicleType == vehicleType).toList();
    } catch (e) {
      throw Exception('차량별 정비 기록 조회 중 오류가 발생했습니다: $e');
    }
  }

  // 정비 기록 삭제
  Future<void> deleteMaintenanceRecord(String recordId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingRecords = await getAllMaintenanceRecords();
      
      // 해당 ID의 기록 제거
      existingRecords.removeWhere((record) => record.id == recordId);
      
      // JSON으로 변환하여 저장
      final recordsJson = existingRecords.map((record) => record.toJson()).toList();
      await prefs.setString(_recordsKey, jsonEncode(recordsJson));
    } catch (e) {
      throw Exception('정비 기록 삭제 중 오류가 발생했습니다: $e');
    }
  }

  // 정비 기록 수정
  Future<void> updateMaintenanceRecord(MaintenanceRecord updatedRecord) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingRecords = await getAllMaintenanceRecords();
      
      // 해당 ID의 기록 찾아서 교체
      final index = existingRecords.indexWhere((record) => record.id == updatedRecord.id);
      if (index != -1) {
        existingRecords[index] = updatedRecord;
        
        // 날짜순으로 정렬
        existingRecords.sort((a, b) => b.maintenanceDate.compareTo(a.maintenanceDate));
        
        // JSON으로 변환하여 저장
        final recordsJson = existingRecords.map((record) => record.toJson()).toList();
        await prefs.setString(_recordsKey, jsonEncode(recordsJson));
      } else {
        throw Exception('수정할 정비 기록을 찾을 수 없습니다.');
      }
    } catch (e) {
      throw Exception('정비 기록 수정 중 오류가 발생했습니다: $e');
    }
  }

  // 통계 정보 조회
  Future<Map<String, dynamic>> getMaintenanceStatistics() async {
    try {
      final allRecords = await getAllMaintenanceRecords();
      
      if (allRecords.isEmpty) {
        return {
          'totalRecords': 0,
          'totalCost': 0.0,
          'carRecords': 0,
          'bikeRecords': 0,
          'carCost': 0.0,
          'bikeCost': 0.0,
        };
      }
      
      final carRecords = allRecords.where((r) => r.vehicleType == VehicleType.car).toList();
      final bikeRecords = allRecords.where((r) => r.vehicleType == VehicleType.bike).toList();
      
      final totalCost = allRecords.fold(0.0, (sum, record) => sum + record.cost);
      final carCost = carRecords.fold(0.0, (sum, record) => sum + record.cost);
      final bikeCost = bikeRecords.fold(0.0, (sum, record) => sum + record.cost);
      
      return {
        'totalRecords': allRecords.length,
        'totalCost': totalCost,
        'carRecords': carRecords.length,
        'bikeRecords': bikeRecords.length,
        'carCost': carCost,
        'bikeCost': bikeCost,
      };
    } catch (e) {
      throw Exception('통계 정보 조회 중 오류가 발생했습니다: $e');
    }
  }
}
