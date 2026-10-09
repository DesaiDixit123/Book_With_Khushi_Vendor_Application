import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'add_service_controller.dart';
import '../../../constants/app_colors.dart';

class AddServiceScreen extends StatelessWidget {
  const AddServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddServiceController());

    return Scaffold(
      backgroundColor: AppColors.beigeCream,
      appBar: AppBar(
        title: Obx(() => Text(controller.isEditMode.value ? 'Edit Service' : 'Add Service')),
      ),
      body: Obx(() {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Service Status Dropdown
              const Text(
                'Service Status*',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyBlue),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: controller.selectedStatus.value,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: '1', child: Text('Active')),
                  DropdownMenuItem(value: '0', child: Text('Inactive')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    controller.selectedStatus.value = val;
                  }
                },
              ),
              const SizedBox(height: 16),

              // 2. Serial Number Input & helper text
              const Text(
                'Serial Number*',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyBlue),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: controller.serialNumController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter Serial Number',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'The higher the serial number is, the later the service will be shown.',
                style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),

              // 3. Available Variant Selector (Yes / No)
              const Text(
                'Available Variant*',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyBlue),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => controller.hasVariants.value = true,
                      child: Container(
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: controller.hasVariants.value ? AppColors.navyBlue : Colors.white,
                          border: Border.all(color: AppColors.navyBlue),
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                        ),
                        child: Text(
                          'Yes',
                          style: TextStyle(
                            color: controller.hasVariants.value ? Colors.white : AppColors.navyBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => controller.hasVariants.value = false,
                      child: Container(
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: !controller.hasVariants.value ? AppColors.navyBlue : Colors.white,
                          border: Border.all(color: AppColors.navyBlue),
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                        ),
                        child: Text(
                          'No',
                          style: TextStyle(
                            color: !controller.hasVariants.value ? Colors.white : AppColors.navyBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                '*The variant creation form appear below when select yes',
                style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),

              // 4. Price Type Dropdown
              const Text(
                'Price Type*',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyBlue),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: controller.selectedPriceType.value,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
                  DropdownMenuItem(value: 'per person', child: Text('Per Person')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    controller.selectedPriceType.value = val;
                  }
                },
              ),
              const SizedBox(height: 16),

              // 5. Price (in INR) - show if variants is No
              if (!controller.hasVariants.value) ...[
                const Text(
                  'Price (in INR)*',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyBlue),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: controller.priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Enter price',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 6. English Language translation container box (violet header)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Violet header matching mockup
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: const BoxDecoration(
                        color: AppColors.navyBlue, // Brand Deep Burgundy
                        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                      ),
                      child: const Text(
                        'English Language (Default)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Box fields body
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Service Title
                          const Text(
                            'Service Title*',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyBlue),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: controller.titleController,
                            decoration: InputDecoration(
                              hintText: 'Enter Service Title',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Meta Keywords
                          const Text(
                            'Meta Keywords',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyBlue),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: controller.keywordsController,
                            decoration: InputDecoration(
                              hintText: 'Enter Meta Keywords',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Meta Description
                          const Text(
                            'Meta Description',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyBlue),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: controller.descController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'Enter Meta Description',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 7. Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.maroon, // Brand Burgundy
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }
}
