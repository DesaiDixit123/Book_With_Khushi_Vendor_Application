import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'forms_controller.dart';
import '../../widgets/app_drawer.dart';
import '../../constants/app_colors.dart';
import '../../routes/app_routes.dart';

class FormsScreen extends StatefulWidget {
  const FormsScreen({super.key});

  @override
  State<FormsScreen> createState() => _FormsScreenState();
}

class _FormsScreenState extends State<FormsScreen> {
  late FormsController controller;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    controller = Get.put(FormsController());
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase().trim()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forms')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.addForm),
        backgroundColor: AppColors.maroon,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Form',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // ── Search Bar ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by form name...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                isDense: true,
              ),
            ),
          ),
          // ── List ──────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final filtered = controller.formsList
                  .where((f) => (f['name'] ?? '').toString().toLowerCase().contains(_query))
                  .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 72, color: AppColors.navyBlue.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        _query.isNotEmpty ? 'NO RESULTS FOUND' : 'NO FORM FOUND!',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                            color: Colors.grey, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _query.isNotEmpty
                            ? 'No form matches "$_query"'
                            : 'Tap the button below to create a new form.',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.fetchForms,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final form = filtered[index];
                    return _FormCard(
                      form: form,
                      onEdit: () {
                        controller.selectedForm = form;
                        Get.toNamed(AppRoutes.editForm);
                      },
                      onManage: () {
                        controller.selectedForm = form;
                        controller.fetchInputs(form['id']);
                        Get.toNamed(AppRoutes.manageFormInputs);
                      },
                      onDelete: () => _confirmDelete(context, controller, form['id']),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, FormsController controller, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Form'),
        content: const Text('Are you sure you want to delete this form?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); controller.deleteForm(id); },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final Map<String, dynamic> form;
  final VoidCallback onEdit;
  final VoidCallback onManage;
  final VoidCallback onDelete;

  const _FormCard({required this.form, required this.onEdit, required this.onManage, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isActive = form['status'].toString() == '1';
    final languageName = form['language']?['name'] ?? 'Unknown Language';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.navyBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.assignment, color: AppColors.navyBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(form['name'] ?? '',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                              color: AppColors.navyBlue)),
                      const SizedBox(height: 2),
                      Text(languageName,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.success.withOpacity(0.1) : Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isActive ? AppColors.success : Colors.grey),
                  ),
                  child: Text(isActive ? 'Active' : 'Inactive',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: isActive ? AppColors.success : Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onManage,
                    icon: const Icon(Icons.input, size: 16),
                    label: const Text('Form Inputs', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF17a2b8),
                      side: const BorderSide(color: Color(0xFF17a2b8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navyBlue,
                    side: const BorderSide(color: AppColors.navyBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text(''),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
