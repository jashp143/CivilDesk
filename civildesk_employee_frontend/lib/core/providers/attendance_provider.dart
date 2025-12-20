import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/attendance.dart';
import '../../models/page_response.dart';
import '../constants/app_constants.dart';
import '../services/api_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Attendance> _attendanceList = [];
  Attendance? _todayAttendance;
  bool _isLoading = false;
  String? _error;
  
  // Pagination state
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _hasMore = true;
  final int _pageSize = 20;

  List<Attendance> get attendanceList => _attendanceList;
  Attendance? get todayAttendance => _todayAttendance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalElements => _totalElements;
  bool get hasMore => _hasMore;

  Future<void> fetchAttendanceHistory({
    DateTime? startDate,
    DateTime? endDate,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 0;
      _attendanceList.clear();
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'size': _pageSize,
        'sortBy': 'date',
        'sortDir': 'DESC',
      };
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
      }

      final response = await _apiService.get(
        '${AppConstants.attendanceEndpoint}/my-attendance',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          
          // Check if response is paginated (has 'content' field) or a list
          if (data is Map && data.containsKey('content')) {
            final pageResponse = PageResponse.fromJson(
              Map<String, dynamic>.from(data),
              (json) => Attendance.fromJson(json),
            );
            
            if (refresh || _currentPage == 0) {
              _attendanceList = pageResponse.content;
            } else {
              _attendanceList.addAll(pageResponse.content);
            }
            
            _currentPage = pageResponse.number;
            _totalPages = pageResponse.totalPages;
            _totalElements = pageResponse.totalElements;
            _hasMore = pageResponse.hasMore;
          } else {
            // Fallback for non-paginated response
            final List<dynamic> dataList = data as List<dynamic>;
            final attendances = dataList
                .map((json) => Attendance.fromJson(json as Map<String, dynamic>))
                .toList();
            
            if (refresh || _currentPage == 0) {
              _attendanceList = attendances;
            } else {
              _attendanceList.addAll(attendances);
            }
            
            _hasMore = false;
            _totalElements = _attendanceList.length;
            _totalPages = 1;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching attendance history: $e');
      if (e is DioException) {
        _error = e.response?.data?['message'] as String? ?? 'Failed to fetch attendance history';
      } else {
        _error = 'Failed to fetch attendance history';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more attendance records (next page)
  Future<void> loadMoreAttendance({DateTime? startDate, DateTime? endDate}) async {
    if (!_hasMore || _isLoading) return;
    await fetchAttendanceHistory(
      startDate: startDate,
      endDate: endDate,
      refresh: false,
    );
  }

  // Refresh attendance (reload from beginning)
  Future<void> refreshAttendance({DateTime? startDate, DateTime? endDate}) async {
    await fetchAttendanceHistory(
      startDate: startDate,
      endDate: endDate,
      refresh: true,
    );
  }

  Future<void> fetchTodayAttendance() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await _apiService.get(
        '${AppConstants.attendanceEndpoint}/my-attendance',
        queryParameters: {'date': today},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> data = responseData['data'] as List<dynamic>;
          if (data.isNotEmpty) {
            _todayAttendance = Attendance.fromJson(data[0] as Map<String, dynamic>);
          } else {
            _todayAttendance = null;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching today attendance: $e');
      if (e is DioException) {
        _error = e.response?.data?['message'] as String? ?? 'Failed to fetch today\'s attendance';
      } else {
        _error = 'Failed to fetch today\'s attendance';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Note: Attendance marking is done by Admin/HR only
  // Employees can only view their attendance

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

