import 'package:intl/intl.dart';
import '../../models/leave.dart';
import '../../models/expense.dart';
import '../../models/overtime.dart';
import '../../models/task.dart';

/// Utility class for building formatted WhatsApp messages
class MessageBuilder {
  /// Builds a leave request notification message
  static String buildLeaveMessage({
    required Leave leave,
    required LeaveStatus status,
    String? adminNote,
  }) {
    final employeeName = leave.employeeName;
    final isApproved = status == LeaveStatus.APPROVED;
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    final buffer = StringBuffer();
    buffer.writeln('Dear $employeeName,');
    buffer.writeln();
    buffer.writeln(
      isApproved
          ? 'This is to inform you that your leave request has been approved.'
          : 'This is to inform you that your leave request has been rejected.',
    );
    buffer.writeln();
    buffer.writeln('Details:');
    buffer.writeln('• Leave Type: ${leave.leaveTypeDisplay}');
    buffer.writeln('• Duration: ${leave.totalDays.toStringAsFixed(1)} ${leave.totalDays == 1 ? 'day' : 'days'}');
    buffer.writeln('• From: ${dateFormat.format(leave.startDate)}');
    buffer.writeln('• To: ${dateFormat.format(leave.endDate)}');
    
    if (leave.isHalfDay) {
      buffer.writeln('• Half Day: ${leave.halfDayPeriodDisplay ?? 'N/A'}');
    }
    
    buffer.writeln('• Reason: ${leave.reason}');
    buffer.writeln();
    
    if (adminNote != null && adminNote.isNotEmpty) {
      buffer.writeln('Admin Comments:');
      buffer.writeln(adminNote);
      buffer.writeln();
    }
    
    if (!isApproved) {
      buffer.writeln('If you have any questions, please contact the administration.');
      buffer.writeln();
    }
    
    buffer.writeln('Best regards,');
    buffer.writeln('Administration Team');
    
    return buffer.toString();
  }

  /// Builds an expense request notification message
  static String buildExpenseMessage({
    required Expense expense,
    required ExpenseStatus status,
    String? adminNote,
  }) {
    final employeeName = expense.employeeName;
    final isApproved = status == ExpenseStatus.APPROVED;
    final dateFormat = DateFormat('yyyy-MM-dd');
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    
    final buffer = StringBuffer();
    buffer.writeln('Dear $employeeName,');
    buffer.writeln();
    buffer.writeln(
      isApproved
          ? 'This is to inform you that your expense request has been approved.'
          : 'This is to inform you that your expense request has been rejected.',
    );
    buffer.writeln();
    buffer.writeln('Details:');
    buffer.writeln('• Amount: ${currencyFormat.format(expense.amount)}');
    buffer.writeln('• Category: ${expense.categoryDisplay}');
    buffer.writeln('• Date: ${dateFormat.format(expense.expenseDate)}');
    buffer.writeln('• Description: ${expense.description}');
    buffer.writeln();
    
    if (adminNote != null && adminNote.isNotEmpty) {
      buffer.writeln('Admin Comments:');
      buffer.writeln(adminNote);
      buffer.writeln();
    }
    
    if (!isApproved) {
      buffer.writeln('If you have any questions, please contact the administration.');
      buffer.writeln();
    }
    
    buffer.writeln('Best regards,');
    buffer.writeln('Administration Team');
    
    return buffer.toString();
  }

  /// Builds an overtime request notification message
  static String buildOvertimeMessage({
    required Overtime overtime,
    required OvertimeStatus status,
    String? adminNote,
  }) {
    final employeeName = overtime.employeeName;
    final isApproved = status == OvertimeStatus.APPROVED;
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    final buffer = StringBuffer();
    buffer.writeln('Dear $employeeName,');
    buffer.writeln();
    buffer.writeln(
      isApproved
          ? 'This is to inform you that your overtime request has been approved.'
          : 'This is to inform you that your overtime request has been rejected.',
    );
    buffer.writeln();
    buffer.writeln('Details:');
    buffer.writeln('• Date: ${dateFormat.format(overtime.date)}');
    buffer.writeln('• Start Time: ${overtime.startTime}');
    buffer.writeln('• End Time: ${overtime.endTime}');
    buffer.writeln('• Reason: ${overtime.reason}');
    buffer.writeln();
    
    if (adminNote != null && adminNote.isNotEmpty) {
      buffer.writeln('Admin Comments:');
      buffer.writeln(adminNote);
      buffer.writeln();
    }
    
    if (!isApproved) {
      buffer.writeln('If you have any questions, please contact the administration.');
      buffer.writeln();
    }
    
    buffer.writeln('Best regards,');
    buffer.writeln('Administration Team');
    
    return buffer.toString();
  }

  /// Builds a task assignment notification message
  static String buildTaskAssignmentMessage({
    required Task task,
    required String employeeName,
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    final buffer = StringBuffer();
    buffer.writeln('Dear $employeeName,');
    buffer.writeln();
    buffer.writeln('You have been assigned a new task.');
    buffer.writeln();
    buffer.writeln('Task Details:');
    buffer.writeln('• Description: ${task.description}');
    buffer.writeln('• Location: ${task.location}');
    buffer.writeln('• Start Date: ${dateFormat.format(task.startDate)}');
    buffer.writeln('• End Date: ${dateFormat.format(task.endDate)}');
    buffer.writeln('• Mode of Travel: ${task.modeOfTravelDisplay}');
    buffer.writeln();
    buffer.writeln('Please review the task details and ensure timely completion.');
    buffer.writeln();
    buffer.writeln('Best regards,');
    buffer.writeln('Administration Team');
    
    return buffer.toString();
  }
}

