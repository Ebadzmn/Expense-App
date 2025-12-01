import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:your_expense/services/config_service.dart';

class MonthSelectorWidget extends StatelessWidget {
  final String selectedMonth;
  final List<String> availableMonths;
  final Function(String) onMonthChanged;
  final bool isViewingCurrentMonth;
  final VoidCallback onGoToCurrentMonth;

  const MonthSelectorWidget({
    super.key,
    required this.selectedMonth,
    required this.availableMonths,
    required this.onMonthChanged,
    required this.isViewingCurrentMonth,
    required this.onGoToCurrentMonth,
  });

  @override
  Widget build(BuildContext context) {
    final configService = Get.find<ConfigService>();
    final currentMonth = configService.getCurrentMonth();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Month selector dropdown and current month button
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedMonth.isNotEmpty ? selectedMonth : null,
                      hint: const Text('Select Month'),
                      isExpanded: true,
                      items: _buildDropdownItems(currentMonth),
                      onChanged: (String? newMonth) {
                        if (newMonth != null) {
                          onMonthChanged(newMonth);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // "Current Month" button
              if (!isViewingCurrentMonth)
                ElevatedButton.icon(
                  onPressed: onGoToCurrentMonth,
                  icon: const Icon(Icons.today, size: 16),
                  label: const Text('Current'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Month navigation arrows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _navigateMonth(-1),
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous Month',
              ),
              Text(
                _formatMonthDisplay(selectedMonth),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                onPressed: () => _navigateMonth(1),
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next Month',
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildDropdownItems(String currentMonth) {
    final items = <DropdownMenuItem<String>>[];
    
    // Add current month first if not in available months
    if (!availableMonths.contains(currentMonth)) {
      items.add(DropdownMenuItem<String>(
        value: currentMonth,
        child: Row(
          children: [
            Text(_formatMonthDisplay(currentMonth)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Current',
                style: TextStyle(fontSize: 10, color: Colors.blue),
              ),
            ),
          ],
        ),
      ));
    }
    
    // Add available months
    for (final month in availableMonths) {
      final isCurrentMonth = month == currentMonth;
      items.add(DropdownMenuItem<String>(
        value: month,
        child: Row(
          children: [
            Text(_formatMonthDisplay(month)),
            if (isCurrentMonth) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Current',
                  style: TextStyle(fontSize: 10, color: Colors.green),
                ),
              ),
            ],
          ],
        ),
      ));
    }
    
    return items;
  }

  String _formatMonthDisplay(String monthYear) {
    try {
      final parts = monthYear.split('-');
      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final date = DateTime(year, month);
        return DateFormat('MMMM yyyy').format(date);
      }
    } catch (e) {
      // Fallback to original string if parsing fails
    }
    return monthYear;
  }

  void _navigateMonth(int direction) {
    try {
      final parts = selectedMonth.split('-');
      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        
        final currentDate = DateTime(year, month);
        final newDate = DateTime(currentDate.year, currentDate.month + direction);
        final newMonth = DateFormat('yyyy-MM').format(newDate);
        
        onMonthChanged(newMonth);
      }
    } catch (e) {
      print('Error navigating month: $e');
    }
  }
}

/// Helper widget for showing month statistics
class MonthStatsWidget extends StatelessWidget {
  final String selectedMonth;
  final int itemCount;
  final double totalAmount;
  final String itemType; // 'expenses' or 'incomes'

  const MonthStatsWidget({
    super.key,
    required this.selectedMonth,
    required this.itemCount,
    required this.totalAmount,
    required this.itemType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                itemCount.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                itemType,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey.shade300,
          ),
          Column(
            children: [
              Text(
                '\$${totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: itemType == 'expenses' ? Colors.red : Colors.green,
                ),
              ),
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}