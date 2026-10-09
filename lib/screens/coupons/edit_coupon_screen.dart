import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'coupons_controller.dart';
import '../../constants/app_colors.dart';

class EditCouponScreen extends StatefulWidget {
  const EditCouponScreen({super.key});

  @override
  State<EditCouponScreen> createState() => _EditCouponScreenState();
}

class _EditCouponScreenState extends State<EditCouponScreen> {
  final CouponsController _controller = Get.find<CouponsController>();
  late Map<String, dynamic> coupon;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();

  String _couponType = 'fixed';
  String _spaceType = 'fixed_time_slot_rental';
  DateTime? _startDate;
  DateTime? _endDate;

  // Selected space IDs
  final List<int> _selectedSpaces = [];

  @override
  void initState() {
    super.initState();
    coupon = Get.arguments;
    _controller.fetchPrerequisites();

    _nameCtrl.text = coupon['name'] ?? '';
    _codeCtrl.text = coupon['code'] ?? '';
    _valueCtrl.text = coupon['value'].toString();
    _serialCtrl.text = coupon['serial_number'].toString();
    
    _couponType = coupon['coupon_type'] ?? 'fixed';
    _spaceType = coupon['space_type'] ?? 'fixed_time_slot_rental';
    
    if (coupon['start_date'] != null && coupon['start_date'].isNotEmpty) {
      _startDate = DateTime.parse(coupon['start_date']);
    }
    if (coupon['end_date'] != null && coupon['end_date'].isNotEmpty) {
      _endDate = DateTime.parse(coupon['end_date']);
    }

    if (coupon['spaces'] != null) {
      for (var s in coupon['spaces']) {
        if (s is String) {
          _selectedSpaces.add(int.parse(s));
        } else {
          _selectedSpaces.add(s);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _valueCtrl.dispose();
    _serialCtrl.dispose();
    super.dispose();
  }

  // Maps backend space_type value (1, 2, 3) to dropdown space_type key
  int _getSpaceTypeNumeric(String key) {
    switch (key) {
      case 'fixed_time_slot_rental':
        return 1;
      case 'hourly_rental':
        return 2;
      case 'multi_day_rental':
        return 3;
      default:
        return 1;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      Get.snackbar('Validation Error', 'Please select start and end dates',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (_selectedSpaces.isEmpty) {
      Get.snackbar('Validation Error', 'Please select at least one space',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    _controller.editCoupon(
      id: coupon['id'],
      name: _nameCtrl.text.trim(),
      code: _codeCtrl.text.trim().toUpperCase(),
      type: _couponType,
      value: double.parse(_valueCtrl.text.trim()),
      startDate: _startDate!.toString().split(' ')[0],
      endDate: _endDate!.toString().split(' ')[0],
      spaceType: _spaceType,
      serialNumber: int.parse(_serialCtrl.text.trim()),
      spaces: _selectedSpaces,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Coupon'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Name ──
                const Text('Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyBlue)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _inputDeco('Enter Coupon Name'),
                  validator: (v) => v!.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                // ── Code ──
                const Text('Code *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyBlue)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _codeCtrl,
                  decoration: _inputDeco('Enter Coupon Code'),
                  validator: (v) => v!.isEmpty ? 'Code is required' : null,
                ),
                const SizedBox(height: 16),

                // ── Row: Coupon Type & Value ──
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Coupon Type *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyBlue)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _couponType,
                            decoration: _inputDeco('Select Type'),
                            dropdownColor: Colors.white,
                            items: const [
                              DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
                              DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
                            ],
                            onChanged: (v) => setState(() => _couponType = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Value *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyBlue)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _valueCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _inputDeco('Enter Value'),
                            validator: (v) => v!.isEmpty ? 'Value is required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Row: Start Date & End Date ──
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Date *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyBlue)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 3650)),
                              );
                              if (d != null) setState(() => _startDate = d);
                            },
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _startDate == null ? 'Select Date' : _startDate!.toString().split(' ')[0],
                                    style: TextStyle(color: _startDate == null ? Colors.grey : Colors.black87, fontSize: 14),
                                  ),
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('End Date *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyBlue)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: _startDate ?? DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 3650)),
                              );
                              if (d != null) setState(() => _endDate = d);
                            },
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _endDate == null ? 'Select Date' : _endDate!.toString().split(' ')[0],
                                    style: TextStyle(color: _endDate == null ? Colors.grey : Colors.black87, fontSize: 14),
                                  ),
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Space Type ──
                const Text('Space Type *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyBlue)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _spaceType,
                  decoration: _inputDeco('Select Space Type'),
                  dropdownColor: Colors.white,
                  items: const [
                    DropdownMenuItem(value: 'fixed_time_slot_rental', child: Text('Fixed Timeslot Rental')),
                    DropdownMenuItem(value: 'hourly_rental', child: Text('Hourly Rental')),
                    DropdownMenuItem(value: 'multi_day_rental', child: Text('Multi Day Rental')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _spaceType = v!;
                      // Clear previously selected spaces when type changes
                      _selectedSpaces.clear();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // ── Spaces (Multi-select checkbox list matching the numeric space_type) ──
                const Text('Spaces *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyBlue)),
                const SizedBox(height: 6),
                Obx(() {
                  if (_controller.isLoadingPrerequisites.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  // Filter spaces from prerequisites matching the active space type selection
                  final int numericType = _getSpaceTypeNumeric(_spaceType);
                  final filteredSpaces = _controller.spacesPrerequisites
                      .where((s) => s['space_type'].toString() == numericType.toString())
                      .toList();

                  if (filteredSpaces.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text('No spaces available for this Space Type.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredSpaces.length,
                      itemBuilder: (context, index) {
                        final space = filteredSpaces[index];
                        final int spaceId = space['id'];
                        final isChecked = _selectedSpaces.contains(spaceId);

                        return CheckboxListTile(
                          title: Text(space['title'] ?? '', style: const TextStyle(fontSize: 13)),
                          value: isChecked,
                          activeColor: AppColors.navyBlue,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedSpaces.add(spaceId);
                              } else {
                                _selectedSpaces.remove(spaceId);
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        );
                      },
                    ),
                  );
                }),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('This coupon can be applied to these spaces.', style: TextStyle(color: Color(0xFFF0AD4E), fontSize: 12, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('Leave this field empty for all spaces.', style: TextStyle(color: Color(0xFFF0AD4E), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Serial Number ──
                const Text('Serial Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyBlue)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _serialCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('Enter Serial Number'),
                  validator: (v) => v!.isEmpty ? 'Serial Number is required' : null,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Coupons with higher serial numbers will appear later in the list.', style: TextStyle(color: Color(0xFFF0AD4E), fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 30),

                // ── Submit Button ──
                Obx(() => SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _controller.isSaving.value ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.maroon,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _controller.isSaving.value
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Update Coupon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.navyBlue)),
      );
}
