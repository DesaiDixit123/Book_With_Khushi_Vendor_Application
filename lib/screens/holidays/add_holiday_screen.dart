import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'holidays_controller.dart';
import '../../constants/app_colors.dart';

class AddHolidayScreen extends StatefulWidget {
  const AddHolidayScreen({super.key});

  @override
  State<AddHolidayScreen> createState() => _AddHolidayScreenState();
}

class _AddHolidayScreenState extends State<AddHolidayScreen> {
  DateTime? _selectedDate;
  final HolidaysController _controller = Get.find<HolidaysController>();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navyBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.navyBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d'; // API expects Y-m-d
  }

  String _displayDate(DateTime date) {
    final months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  void _save() {
    if (_selectedDate == null) {
      Get.snackbar(
        'Date Required',
        'Please select a holiday date.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    _controller.addHoliday(_formatDate(_selectedDate!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Holiday'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.navyBlue.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.navyBlue.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.navyBlue.withOpacity(0.7), size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Select a date to mark as a holiday. Customers will not be able to book on this date.',
                      style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Date label
            const Text(
              'Date *',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.navyBlue,
              ),
            ),
            const SizedBox(height: 10),

            // Date picker tile
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedDate != null
                        ? AppColors.navyBlue
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: _selectedDate != null
                          ? AppColors.navyBlue
                          : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate != null
                          ? _displayDate(_selectedDate!)
                          : 'Select a date',
                      style: TextStyle(
                        fontSize: 15,
                        color: _selectedDate != null
                            ? AppColors.navyBlue
                            : Colors.grey,
                        fontWeight: _selectedDate != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down,
                        color: _selectedDate != null
                            ? AppColors.navyBlue
                            : Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Save button
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _controller.isSaving.value ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _controller.isSaving.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Save Holiday',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
