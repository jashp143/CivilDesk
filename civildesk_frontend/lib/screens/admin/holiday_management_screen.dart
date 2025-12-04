import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/holiday_provider.dart';
import '../../models/holiday.dart';
import '../../widgets/admin_layout.dart';

class HolidayManagementScreen extends StatefulWidget {
  const HolidayManagementScreen({super.key});

  @override
  State<HolidayManagementScreen> createState() => _HolidayManagementScreenState();
}

class _HolidayManagementScreenState extends State<HolidayManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HolidayProvider>().loadHolidays();
    });
  }

  void _showAddHolidayDialog({Holiday? holiday}) {
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = holiday?.date ?? DateTime.now();
    final nameController = TextEditingController(text: holiday?.name ?? '');
    final descriptionController = TextEditingController(text: holiday?.description ?? '');
    bool isActive = holiday?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                holiday == null ? Icons.add_circle : Icons.edit,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                holiday == null ? 'Add Holiday' : 'Edit Holiday',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Picker
                  Text(
                    'Date',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('MMM dd, yyyy (EEEE)').format(selectedDate),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (selectedDate.weekday == 7) // Sunday
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.purple),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Sunday is already a non-working day. No attendance will be marked.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Name Field
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Holiday Name *',
                      hintText: 'e.g., Republic Day',
                      prefixIcon: const Icon(Icons.event),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Holiday name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Description Field
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Add description about the holiday',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  // Active Toggle
                  SwitchListTile(
                    title: const Text('Active'),
                    subtitle: const Text('Mark attendance for all employees'),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() {
                        isActive = value;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newHoliday = Holiday(
                    id: holiday?.id,
                    date: selectedDate,
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    isActive: isActive,
                  );

                  final provider = context.read<HolidayProvider>();
                  bool success;
                  if (newHoliday.id == null) {
                    success = await provider.createHoliday(newHoliday);
                  } else {
                    success = await provider.updateHoliday(newHoliday.id!, newHoliday);
                  }

                  if (context.mounted) {
                    if (success) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            newHoliday.id == null
                                ? 'Holiday created successfully! Normalized attendance marked for all employees.'
                                : 'Holiday updated successfully!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.error ?? 'Operation failed'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: Text(holiday == null ? 'Create' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Holiday holiday) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete Holiday'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${holiday.name}"?\n\nThis will remove normalized attendance for all employees on this date.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<HolidayProvider>();
              final success = await provider.deleteHoliday(holiday.id!);

              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Holiday deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.error ?? 'Failed to delete holiday'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: AppRoutes.holidayManagement,
      title: const Text('Holiday Management'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            context.read<HolidayProvider>().loadHolidays();
          },
          tooltip: 'Refresh',
        ),
        FilledButton.icon(
          onPressed: () => _showAddHolidayDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Add Holiday'),
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.event,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Holiday Management',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Define holidays and automatically mark normalized attendance',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primaryContainer,
              width: 1,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'When you create a holiday, normalized attendance (Check-in: 09:00, Lunch-out: 13:00, Lunch-in: 14:00, Check-out: 18:00) will be automatically marked for all employees. If the holiday falls on Sunday, no attendance is marked as Sunday is already a non-working day.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Consumer<HolidayProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.holidays.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (provider.error != null && provider.holidays.isEmpty) {
          return _buildErrorState(provider.error!);
        }

        if (provider.holidays.isEmpty) {
          return _buildEmptyState();
        }

        return _buildHolidaysList(provider.holidays);
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                context.read<HolidayProvider>().loadHolidays();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Holidays',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click "Add Holiday" to define company holidays',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolidaysList(List<Holiday> holidays) {
    // Group holidays by year
    final Map<int, List<Holiday>> holidaysByYear = {};
    for (var holiday in holidays) {
      final year = holiday.date.year;
      if (!holidaysByYear.containsKey(year)) {
        holidaysByYear[year] = [];
      }
      holidaysByYear[year]!.add(holiday);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Holidays',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...holidaysByYear.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key.toString(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 12),
              ...entry.value.map((holiday) => _buildHolidayCard(holiday)),
              const SizedBox(height: 24),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildHolidayCard(Holiday holiday) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final dayFormat = DateFormat('EEEE');
    final isSunday = holiday.date.weekday == 7;
    final isPast = holiday.date.isBefore(DateTime.now());

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSunday
              ? Colors.purple.withOpacity(0.3)
              : holiday.isActive
                  ? Colors.green.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isSunday
                  ? Colors.purple.withOpacity(0.05)
                  : holiday.isActive
                      ? Colors.green.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.05),
              Colors.transparent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSunday
                  ? Colors.purple.withOpacity(0.2)
                  : holiday.isActive
                      ? Colors.green.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                holiday.date.day.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isSunday
                      ? Colors.purple
                      : holiday.isActive
                          ? Colors.green
                          : Colors.grey,
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  holiday.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (isSunday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Sunday',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.purple,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                  ),
                ),
              if (!holiday.isActive)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Inactive',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${dateFormat.format(holiday.date)} • ${dayFormat.format(holiday.date)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (holiday.description != null && holiday.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  holiday.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (isSunday) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 12,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'No attendance marked (Sunday is non-working)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.purple,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ] else if (holiday.isActive) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Normalized attendance marked for all employees',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showAddHolidayDialog(holiday: holiday),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteConfirmation(holiday),
                tooltip: 'Delete',
                color: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

