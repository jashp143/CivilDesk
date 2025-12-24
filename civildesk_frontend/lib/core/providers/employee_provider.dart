import 'package:flutter/foundation.dart';
import '../../models/employee.dart';
import '../services/employee_service.dart';

class EmployeeProvider extends ChangeNotifier {
  final EmployeeService _employeeService = EmployeeService();

  List<Employee> _employees = [];
  Employee? _selectedEmployee;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;

  // Filters
  String? _searchQuery;
  String? _departmentFilter;
  String? _designationFilter;
  EmploymentStatus? _statusFilter;
  EmploymentType? _typeFilter;

  List<Employee> get employees => _employees;
  Employee? get selectedEmployee => _selectedEmployee;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalElements => _totalElements;
  bool get hasMore => _currentPage < _totalPages - 1;

  String? get searchQuery => _searchQuery;
  String? get departmentFilter => _departmentFilter;
  String? get designationFilter => _designationFilter;
  EmploymentStatus? get statusFilter => _statusFilter;
  EmploymentType? get typeFilter => _typeFilter;

  Future<void> loadEmployees({
    int page = 0,
    int size = 25,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 0;
      _employees.clear();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      EmployeeListResponse response;

      if (_searchQuery != null ||
          _departmentFilter != null ||
          _designationFilter != null ||
          _statusFilter != null ||
          _typeFilter != null) {
        response = await _employeeService.searchEmployees(
          search: _searchQuery,
          department: _departmentFilter,
          designation: _designationFilter,
          status: _statusFilter,
          type: _typeFilter,
          page: page,
          size: size,
        );
      } else {
        response = await _employeeService.getAllEmployees(
          page: page,
          size: size,
        );
      }

      if (refresh || page == 0) {
        _employees = response.content;
      } else {
        _employees.addAll(response.content);
      }

      _currentPage = response.number;
      _totalPages = response.totalPages;
      _totalElements = response.totalElements;

      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error loading employees: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreEmployees() async {
    if (!hasMore || _isLoading) return;
    await loadEmployees(page: _currentPage + 1, size: 20);
  }

  Future<void> loadEmployeeById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedEmployee = await _employeeService.getEmployeeById(id);
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error loading employee: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createEmployee(Employee employee) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final createdEmployee = await _employeeService.createEmployee(employee);
      _employees.insert(0, createdEmployee);
      _totalElements++;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error creating employee: $_error');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEmployee(int id, Employee employee) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedEmployee = await _employeeService.updateEmployee(id, employee);
      final index = _employees.indexWhere((e) => e.id == id);
      if (index != -1) {
        _employees[index] = updatedEmployee;
      }
      if (_selectedEmployee?.id == id) {
        _selectedEmployee = updatedEmployee;
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error updating employee: $_error');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteEmployee(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _employeeService.deleteEmployee(id);
      _employees.removeWhere((e) => e.id == id);
      if (_selectedEmployee?.id == id) {
        _selectedEmployee = null;
      }
      _totalElements--;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error deleting employee: $_error');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> generateEmployeeCredentials(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _employeeService.generateEmployeeCredentials(id);
      // Reload employee to get updated data
      if (_selectedEmployee?.id == id) {
        await loadEmployeeById(id);
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error generating employee credentials: $_error');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDepartmentFilter(String? department) {
    _departmentFilter = department;
    notifyListeners();
  }

  void setDesignationFilter(String? designation) {
    _designationFilter = designation;
    notifyListeners();
  }

  void setStatusFilter(EmploymentStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setTypeFilter(EmploymentType? type) {
    _typeFilter = type;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = null;
    _departmentFilter = null;
    _designationFilter = null;
    _statusFilter = null;
    _typeFilter = null;
    notifyListeners();
  }

  void clearSelectedEmployee() {
    _selectedEmployee = null;
    notifyListeners();
  }
}

