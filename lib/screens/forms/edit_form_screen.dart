import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'forms_controller.dart';
import '../../constants/app_colors.dart';

class EditFormScreen extends StatefulWidget {
  const EditFormScreen({super.key});

  @override
  State<EditFormScreen> createState() => _EditFormScreenState();
}

class _EditFormScreenState extends State<EditFormScreen> {
  final FormsController _controller = Get.find<FormsController>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  int? _selectedLanguageId;
  int? _selectedStatus;

  @override
  void initState() {
    super.initState();
    // Pre-populate with selected form values
    final form = _controller.selectedForm;
    if (form != null) {
      _nameController.text = form['name'] ?? '';
      _selectedLanguageId = form['language_id'] is int
          ? form['language_id']
          : int.tryParse(form['language_id'].toString());
      _selectedStatus = form['status'] is int
          ? form['status']
          : int.tryParse(form['status'].toString());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLanguageId == null) {
      Get.snackbar('Required', 'Please select a language.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    if (_selectedStatus == null) {
      Get.snackbar('Required', 'Please select a status.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    _controller.updateForm(
      id: _controller.selectedForm!['id'],
      languageId: _selectedLanguageId!,
      name: _nameController.text.trim(),
      status: _selectedStatus!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Form'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Language Dropdown ─────────────────────────────
              _buildLabel('Language *'),
              const SizedBox(height: 8),
              Obx(() {
                final langs = _controller.languagesList;
                return DropdownButtonFormField<int>(
                  value: _selectedLanguageId,
                  decoration: _inputDecoration('Select a Language'),
                  items: langs
                      .map((l) => DropdownMenuItem<int>(
                            value: l['id'] as int,
                            child: Text(l['name'] ?? ''),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedLanguageId = val),
                  validator: (v) => v == null ? 'Please select a language' : null,
                );
              }),
              const SizedBox(height: 24),

              // ── Name Field ────────────────────────────────────
              _buildLabel('Name *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Enter Form Name'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a form name'
                    : null,
              ),
              const SizedBox(height: 24),

              // ── Status Dropdown ───────────────────────────────
              _buildLabel('Status *'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedStatus,
                decoration: _inputDecoration('Select a Status'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Active')),
                  DropdownMenuItem(value: 0, child: Text('Inactive')),
                ],
                onChanged: (val) => setState(() => _selectedStatus = val),
                validator: (v) => v == null ? 'Please select a status' : null,
              ),
              const SizedBox(height: 40),

              // ── Save Button ───────────────────────────────────
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
                              height: 22, width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Update Form',
                              style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
          color: AppColors.navyBlue));

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.navyBlue, width: 1.5)),
      );
}
