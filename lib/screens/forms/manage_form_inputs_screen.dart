import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'forms_controller.dart';
import '../../constants/app_colors.dart';

class ManageFormInputsScreen extends StatefulWidget {
  const ManageFormInputsScreen({super.key});

  @override
  State<ManageFormInputsScreen> createState() => _ManageFormInputsScreenState();
}

class _ManageFormInputsScreenState extends State<ManageFormInputsScreen> {
  final FormsController _controller = Get.find<FormsController>();

  // Create Input Field state
  String _selectedType = 'text';
  bool _isRequired = true;
  final _labelController = TextEditingController();
  final _placeholderController = TextEditingController();
  final _createFormKey = GlobalKey<FormState>();

  final List<Map<String, String>> _inputTypes = [
    {'label': 'Text Field', 'value': 'text'},
    {'label': 'Number Field', 'value': 'number'},
    {'label': 'Select', 'value': 'select'},
    {'label': 'Checkbox', 'value': 'checkbox'},
    {'label': 'Textarea', 'value': 'textarea'},
    {'label': 'Datepicker', 'value': 'date'},
    {'label': 'Timepicker', 'value': 'time'},
    {'label': 'File', 'value': 'file'},
  ];

  @override
  void dispose() {
    _labelController.dispose();
    _placeholderController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_createFormKey.currentState!.validate()) return;
    final formId = _controller.selectedForm!['id'] as int;
    _controller.addInput(
      formId: formId,
      label: _labelController.text.trim(),
      type: _selectedType,
      placeholder: _placeholderController.text.trim(),
      isRequired: _isRequired ? 1 : 0,
    );
    // Reset form after submit
    setState(() {
      _selectedType = 'text';
      _isRequired = true;
      _labelController.clear();
      _placeholderController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final form = _controller.selectedForm;
    final formName = form?['name'] ?? 'Form';

    return Scaffold(
      appBar: AppBar(
        title: Text('Form Inputs — $formName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Form Input Fields List ──────────────────────────
            _buildInputFieldsList(),
            const SizedBox(height: 20),

            // ── Create Input Field Section ──────────────────────
            _buildCreateInputSection(),
          ],
        ),
      ),
    );
  }

  // ─── Left panel: existing fields ────────────────────────────────────────
  Widget _buildInputFieldsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.navyBlue.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Icon(Icons.list_alt, color: AppColors.navyBlue, size: 20),
                SizedBox(width: 8),
                Text('Form Input Fields',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                        color: AppColors.navyBlue)),
              ],
            ),
          ),

          // Info notes
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                    children: [
                      TextSpan(text: '* Do not create ', style: TextStyle(color: Color(0xFFd9534f))),
                      TextSpan(text: 'Name, Email & Phone Number',
                          style: TextStyle(color: Color(0xFF0d6efd), fontWeight: FontWeight.w600)),
                      TextSpan(text: ' input field, it will be in the form by default.',
                          style: TextStyle(color: Color(0xFFd9534f))),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text('* Delete to remove an input field from this form.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFd9534f))),
              ],
            ),
          ),
          const Divider(height: 1),

          // Default fields (Name, Email — always shown)
          _DefaultFieldTile(label: 'Name', placeholder: 'Enter Your Full Name', isRequired: true),
          _DefaultFieldTile(label: 'Email Address', placeholder: 'Enter Your Email Address', isRequired: true),

          // Dynamic fields from API
          Obx(() {
            if (_controller.isLoadingInputs.value) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (_controller.inputsList.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text('No custom input fields yet.',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                ),
              );
            }
            return Column(
              children: _controller.inputsList.map((input) {
                final formId = _controller.selectedForm!['id'] as int;
                return _InputFieldTile(
                  input: input,
                  onDelete: () => _confirmDelete(input['id'], formId),
                );
              }).toList(),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── Right panel: create input ─────────────────────────────────────────
  Widget _buildCreateInputSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.navyBlue.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Icon(Icons.add_circle_outline, color: AppColors.navyBlue, size: 20),
                SizedBox(width: 8),
                Text('Create Input Field',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                        color: AppColors.navyBlue)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _createFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Input Field Type ──────────────────────────
                  const Text('Input Field Type *',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppColors.navyBlue)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _inputTypes.map((t) {
                      final selected = _selectedType == t['value'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedType = t['value']!),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio<String>(
                              value: t['value']!,
                              groupValue: _selectedType,
                              activeColor: AppColors.navyBlue,
                              onChanged: (v) => setState(() => _selectedType = v!),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            Text(t['label']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: selected ? AppColors.navyBlue : Colors.black54,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                )),
                            const SizedBox(width: 4),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ── Required Status ───────────────────────────
                  const Text('Required Status *',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppColors.navyBlue)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isRequired = true),
                          child: Container(
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _isRequired ? AppColors.navyBlue : Colors.grey.shade100,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                              border: Border.all(
                                color: _isRequired ? AppColors.navyBlue : Colors.grey.shade300,
                              ),
                            ),
                            child: Text('Yes',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _isRequired ? Colors.white : Colors.grey,
                                  fontSize: 14,
                                )),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isRequired = false),
                          child: Container(
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: !_isRequired ? AppColors.navyBlue : Colors.grey.shade100,
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                              border: Border.all(
                                color: !_isRequired ? AppColors.navyBlue : Colors.grey.shade300,
                              ),
                            ),
                            child: Text('No',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: !_isRequired ? Colors.white : Colors.grey,
                                  fontSize: 14,
                                )),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Label ─────────────────────────────────────
                  const Text('Label *',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppColors.navyBlue)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _labelController,
                    decoration: _inputDeco('Enter Input Label'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Label is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Placeholder ───────────────────────────────
                  const Text('Placeholder *',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppColors.navyBlue)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _placeholderController,
                    decoration: _inputDeco('Enter Input Placeholder'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Placeholder is required' : null,
                  ),
                  const SizedBox(height: 24),

                  // ── Submit button ─────────────────────────────
                  Obx(() => SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _controller.isSaving.value ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0d6efd),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _controller.isSaving.value
                              ? const SizedBox(height: 20, width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Submit',
                                  style: TextStyle(fontSize: 15,
                                      fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int inputId, int formId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Input'),
        content: const Text('Remove this input field from the form?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _controller.deleteInput(formId, inputId); },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.navyBlue, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red)),
      );
}

// ─── Default field tile (Name, Email — always shown) ──────────────────────
class _DefaultFieldTile extends StatelessWidget {
  final String label;
  final String placeholder;
  final bool isRequired;
  const _DefaultFieldTile({required this.label, required this.placeholder, this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$label${isRequired ? ' *' : ''}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.navyBlue)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('DEFAULT', style: TextStyle(fontSize: 9,
                    fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(placeholder,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ),
        ],
      ),
    );
  }
}

// ─── Custom input field tile ───────────────────────────────────────────────
class _InputFieldTile extends StatelessWidget {
  final Map<String, dynamic> input;
  final VoidCallback onDelete;
  const _InputFieldTile({required this.input, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isRequired = input['is_required'].toString() == '1';
    final type = (input['type'] ?? 'text').toString();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${input['label'] ?? ''}${isRequired ? ' *' : ''}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.navyBlue)),
              ),
              // Type chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.navyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(type.toUpperCase(),
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                        color: AppColors.navyBlue)),
              ),
              const SizedBox(width: 6),
              // Delete
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if ((input['placeholder'] ?? '').toString().isNotEmpty)
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(input['placeholder'],
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
            ),
        ],
      ),
    );
  }
}
