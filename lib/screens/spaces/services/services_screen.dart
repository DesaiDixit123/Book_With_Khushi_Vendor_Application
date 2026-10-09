import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'services_controller.dart';
import '../../../constants/app_colors.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ServicesController());
    final spaceTitle = controller.space['title'] ?? 'Space';

    return Scaffold(
      backgroundColor: AppColors.beigeCream,
      appBar: AppBar(
        title: Text('Services - $spaceTitle'),
      ),
      body: Column(
        children: [
          // Header card with Back and Add Service buttons
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.navyBlue),
                    label: const Text(
                      'Back',
                      style: TextStyle(color: AppColors.navyBlue, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.navyBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.navigateToAddService,
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text(
                      'Add Service',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.maroon,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Main body content displaying the services
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.fetchServices(),
              color: AppColors.maroon,
              backgroundColor: Colors.white,
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.maroon),
                  );
                }

                if (controller.servicesList.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: const Text(
                          'NO SERVICE FOUND FOR THIS SPACE!',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: controller.servicesList.length,
                  itemBuilder: (context, index) {
                    final service = controller.servicesList[index];
                    return _buildServiceCard(context, service, controller);
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> service, ServicesController controller) {
    final status = service['status'] == 1 ? 'Active' : 'Inactive';
    final statusColor = service['status'] == 1 ? AppColors.success : AppColors.error;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    service['title'] ?? 'Untitled Service',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyBlue,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.swap_vert, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Serial: ${service['serial_number'] ?? 0}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(width: 20),
                const Icon(Icons.style, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Variant: ${service['has_sub_services'] == 1 ? 'Yes' : 'No'}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.currency_rupee, size: 16, color: AppColors.maroon),
                const SizedBox(width: 6),
                Text(
                  'Price: ${service['has_sub_services'] == 1 ? "Varies" : "₹${service['price'] ?? 0.0}"} (${service['price_type'] ?? 'Fixed'})',
                  style: const TextStyle(fontSize: 13, color: AppColors.maroon, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => controller.navigateToEditService(service),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () {
                    Get.dialog(
                      AlertDialog(
                        title: const Text('Delete Service'),
                        content: const Text('Are you sure you want to delete this service?'),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Get.back();
                              await controller.deleteService(service['id']);
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
