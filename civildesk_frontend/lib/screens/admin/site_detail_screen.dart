import 'package:flutter/material.dart';
import '../../models/site.dart';
import '../../core/services/site_service.dart';
import '../../core/services/employee_service.dart';
import '../../widgets/admin_layout.dart';
import '../../core/constants/app_routes.dart';
import 'site_management_screen.dart' show EmployeeAssignmentDialog, SiteFormDialog;

class SiteDetailScreen extends StatefulWidget {
  final int siteId;

  const SiteDetailScreen({
    super.key,
    required this.siteId,
  });

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen> {
  final SiteService _siteService = SiteService();
  final EmployeeService _employeeService = EmployeeService();
  Site? _site;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _assignedEmployees = [];
  bool _isLoadingEmployees = false;

  @override
  void initState() {
    super.initState();
    _loadSiteDetails();
  }

  Future<void> _loadSiteDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final site = await _siteService.getSiteById(widget.siteId);
      setState(() {
        _site = site;
        _isLoading = false;
      });
      _loadAssignedEmployees();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAssignedEmployees() async {
    if (_site == null) return;

    setState(() {
      _isLoadingEmployees = true;
    });

    try {
      final employees = await _siteService.getSiteEmployees(_site!.id!);
      setState(() {
        _assignedEmployees = employees;
        _isLoadingEmployees = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingEmployees = false;
      });
    }
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  void _showSiteDialog() {
    showDialog(
      context: context,
      builder: (context) => SiteFormDialog(
        site: _site,
        onSaved: () {
          _loadSiteDetails();
        },
      ),
    );
  }

  void _showEmployeeAssignmentDialog() {
    if (_site == null) return;
    showDialog(
      context: context,
      builder: (context) => EmployeeAssignmentDialog(
        site: _site!,
        siteService: _siteService,
        employeeService: _employeeService,
        onUpdated: () {
          _loadSiteDetails();
        },
      ),
    );
  }

  void _confirmDelete() {
    if (_site == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Site'),
        content: Text('Are you sure you want to delete "${_site!.siteName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await _siteService.deleteSite(_site!.id!);
                if (mounted) {
                  navigator.pop(true); // Return to site list
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Site deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return AdminLayout(
      currentRoute: AppRoutes.siteManagement,
      showBackButton: true,
      title: Text(
        _site?.siteName ?? 'Site Details',
        style: isMobile
            ? Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ) ?? TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                )
            : Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ) ?? TextStyle(
                fontWeight: FontWeight.bold,
              ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showSiteDialog();
                break;
              case 'employees':
                _showEmployeeAssignmentDialog();
                break;
              case 'delete':
                _confirmDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 12),
                  Text('Edit Site'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'employees',
              child: Row(
                children: [
                  Icon(Icons.people_outline, size: 20),
                  SizedBox(width: 12),
                  Text('Manage Employees'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Delete Site', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSiteDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSiteDetails,
                  child: CustomScrollView(
                    slivers: [
                      // Site Header Card
                      SliverToBoxAdapter(
                        child: Container(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: _buildSiteHeader(isMobile),
                        ),
                      ),

                      // Site Information
                      SliverPadding(
                        padding: EdgeInsets.all(isMobile ? 12 : 16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildInfoSection('Site Information', [
                              _buildInfoTile(Icons.qr_code, 'Site Code', _site!.siteCode),
                              if (_site!.description?.isNotEmpty == true)
                                _buildInfoTile(Icons.description, 'Description', _site!.description!),
                              _buildInfoTile(
                                Icons.toggle_on,
                                'Status',
                                _site!.isActive ? 'Active' : 'Inactive',
                                valueColor: _site!.isActive ? Colors.green : Colors.grey,
                              ),
                            ], isMobile: isMobile),
                            
                            const SizedBox(height: 16),
                            
                            _buildInfoSection('Location Details', [
                              if (_site!.fullAddress.isNotEmpty)
                                _buildInfoTile(Icons.location_city, 'Address', _site!.fullAddress),
                              if (_site!.city?.isNotEmpty == true)
                                _buildInfoTile(Icons.location_on, 'City', _site!.city!),
                              if (_site!.state?.isNotEmpty == true)
                                _buildInfoTile(Icons.map, 'State', _site!.state!),
                              if (_site!.pincode?.isNotEmpty == true)
                                _buildInfoTile(Icons.pin, 'Pincode', _site!.pincode!),
                            ], isMobile: isMobile),
                            
                            const SizedBox(height: 16),
                            
                            _buildInfoSection('GPS & Geofence', [
                              _buildInfoTile(Icons.gps_fixed, 'Latitude', _site!.latitude.toStringAsFixed(6)),
                              _buildInfoTile(Icons.gps_fixed, 'Longitude', _site!.longitude.toStringAsFixed(6)),
                              _buildInfoTile(Icons.radio_button_checked, 'Geofence Radius', '${_site!.geofenceRadiusMeters}m'),
                            ], isMobile: isMobile),
                            
                            const SizedBox(height: 16),
                            
                            // Assigned Employees Section
                            _buildEmployeesSection(isMobile),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSiteHeader(bool isMobile) {
    return Row(
      children: [
        Container(
          width: isMobile ? 56 : 64,
          height: isMobile ? 56 : 64,
          decoration: BoxDecoration(
            color: _site!.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.location_on,
            color: _site!.isActive ? Colors.green : Colors.grey,
            size: isMobile ? 32 : 40,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _site!.siteName,
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 12,
                  vertical: isMobile ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: _site!.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _site!.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: _site!.isActive ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children, {bool isMobile = false}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {Color? valueColor, bool isMobile = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 10 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isMobile ? 18 : 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesSection(bool isMobile) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assigned Employees',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showEmployeeAssignmentDialog,
                  icon: const Icon(Icons.people_outline, size: 18),
                  label: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _isLoadingEmployees
                ? const Center(child: CircularProgressIndicator())
                : _assignedEmployees.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'No employees assigned',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _showEmployeeAssignmentDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Assign Employees'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _assignedEmployees.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final assignment = _assignedEmployees[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.primary,
                                size: isMobile ? 20 : 24,
                              ),
                            ),
                            title: Text(
                              assignment['employeeName'] ?? 'Unknown',
                              style: TextStyle(fontSize: isMobile ? 14 : 16),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${assignment['employeeCode'] ?? 'N/A'}'),
                                if (assignment['isPrimary'] == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Chip(
                                      label: const Text('Primary Site'),
                                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                                      labelStyle: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
