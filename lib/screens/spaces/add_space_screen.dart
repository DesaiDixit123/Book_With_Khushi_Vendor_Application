import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'add_space_controller.dart';
import '../../constants/app_colors.dart';

class AddSpaceScreen extends StatelessWidget {
  const AddSpaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddSpaceController());

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Obx(() => Text(
          controller.isEditMode.value ? 'Edit Space' : 'Add New Space',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        )),
        backgroundColor: AppColors.navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isPrerequisitesLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.golden));
        }

        return Column(
          children: [
            // 7-Step Horizontal Stepper Header
            _buildStepperHeader(context, controller),

            // Step Body Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildCurrentStepView(context, controller),
              ),
            ),

            // Bottom Navigation Bar
            _buildBottomNav(context, controller),
          ],
        );
      }),
    );
  }

  // -------------------------------------------------------------
  // STEPPER HEADER (7 STEPS)
  // -------------------------------------------------------------
  Widget _buildStepperHeader(BuildContext context, AddSpaceController controller) {
    final stepTitles = [
      'Basic Info',
      'Category',
      'Media',
      'Documents',
      'Timings',
      'Booking',
      'Review'
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(stepTitles.length, (index) {
            final isCurrent = controller.currentStep.value == index;
            final isCompleted = controller.currentStep.value > index;

            Color circleColor = Colors.grey.shade300;
            Color textColor = Colors.black54;

            if (isCurrent) {
              circleColor = AppColors.navyBlue;
              textColor = AppColors.navyBlue;
            } else if (isCompleted) {
              circleColor = AppColors.success;
              textColor = AppColors.success;
            }

            return InkWell(
              onTap: () {
                if (isCompleted || isCurrent) {
                  controller.goToStep(index);
                }
              },
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: circleColor,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isCurrent ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stepTitles[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  if (index < stepTitles.length - 1)
                    Container(
                      width: 24,
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: isCompleted ? AppColors.success : Colors.grey.shade300,
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // CURRENT STEP ROUTER
  // -------------------------------------------------------------
  Widget _buildCurrentStepView(BuildContext context, AddSpaceController controller) {
    switch (controller.currentStep.value) {
      case 0:
        return _buildStep1BasicInfo(context, controller);
      case 1:
        return _buildStep2CategoryDetails(context, controller);
      case 2:
        return _buildStep3ImagesAndVideos(context, controller);
      case 3:
        return _buildStep4Documents(context, controller);
      case 4:
        return _buildStep5BusinessSettings(context, controller);
      case 5:
        return _buildStep6BookingSettings(context, controller);
      case 6:
        return _buildStep7ReviewAndSubmit(context, controller);
      default:
        return _buildStep1BasicInfo(context, controller);
    }
  }

  // -------------------------------------------------------------
  // STEP 1: BASIC INFORMATION
  // -------------------------------------------------------------
  Widget _buildStep1BasicInfo(BuildContext context, AddSpaceController controller) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Step 1: Basic Information'),
            const SizedBox(height: 16),

            _buildLabelWithAsterisk('Space Title', isRequired: true),
            TextFormField(
              controller: controller.titleController,
              decoration: const InputDecoration(hintText: 'e.g. Royal Wedding Hall & Catering'),
            ),
            const SizedBox(height: 16),

            _buildLabelWithAsterisk('Category', isRequired: true),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(hintText: 'Select Category'),
              initialValue: controller.selectedCategoryId.value,
              items: controller.categories.map((cat) {
                return DropdownMenuItem<int>(
                  value: cat['id'],
                  child: Text(cat['name']?.toString() ?? ''),
                );
              }).toList(),
              onChanged: (val) {
                controller.selectedCategoryId.value = val;
              },
            ),
            const SizedBox(height: 16),

            Obx(() {
              final subcats = controller.currentSubcategories;
              if (subcats.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabelWithAsterisk('Subcategory'),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(hintText: 'Select Subcategory'),
                    value: controller.selectedSubcategoryId.value,
                    items: subcats.map((sub) {
                      final baseAmount = sub['razorpay_base_amount'];
                      final baseText = baseAmount != null ? ' (Base ₹$baseAmount)' : '';
                      return DropdownMenuItem<int>(
                        value: sub['id'] is int ? sub['id'] : int.tryParse(sub['id']?.toString() ?? ''),
                        child: Text('${sub['name']}$baseText'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      controller.selectedSubcategoryId.value = val;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }),

            _buildLabelWithAsterisk('Business Name'),
            TextFormField(
              controller: controller.businessNameController,
              decoration: const InputDecoration(hintText: 'e.g. Khushi Events & Hospitality'),
            ),
            const SizedBox(height: 16),

            _buildLabelWithAsterisk('Owner Name'),
            TextFormField(
              controller: controller.ownerNameController,
              decoration: const InputDecoration(hintText: 'e.g. Rahul Sharma'),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabelWithAsterisk('Mobile Number'),
                      TextFormField(
                        controller: controller.mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(hintText: '10-digit Mobile'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabelWithAsterisk('WhatsApp Number'),
                      TextFormField(
                        controller: controller.whatsappController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(hintText: 'WhatsApp No.'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildLabelWithAsterisk('Email ID'),
            TextFormField(
              controller: controller.emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'owner@example.com'),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabelWithAsterisk('City'),
                      TextFormField(
                        controller: controller.cityController,
                        decoration: const InputDecoration(hintText: 'e.g. Ahmedabad'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabelWithAsterisk('Area / Locality'),
                      TextFormField(
                        controller: controller.areaController,
                        decoration: const InputDecoration(hintText: 'e.g. SG Highway'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildLabelWithAsterisk('Full Address'),
            TextFormField(
              controller: controller.addressController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Complete street address'),
            ),
            const SizedBox(height: 16),

            _buildLabelWithAsterisk('Google Map Location URL'),
            TextFormField(
              controller: controller.googleMapController,
              decoration: const InputDecoration(hintText: 'https://maps.google.com/?q=...'),
            ),
            const SizedBox(height: 16),

            _buildLabelWithAsterisk('Experience (Years)'),
            TextFormField(
              controller: controller.experienceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'e.g. 5'),
            ),
            const SizedBox(height: 16),

            _buildLabelWithAsterisk('About Business'),
            TextFormField(
              controller: controller.descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Describe your business services, highlights and offerings...'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 2: DYNAMIC CATEGORY DETAILS
  // -------------------------------------------------------------
  Widget _buildStep2CategoryDetails(BuildContext context, AddSpaceController controller) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Step 2: Category Specific Details'),
            const SizedBox(height: 8),
            Text(
              'Fields are dynamically tailored for the selected category.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // ---------------------------------------------------------
            // CATEGORY TYPES / OFFERINGS & INDIVIDUAL PRICING
            // ---------------------------------------------------------
            Obx(() {
              final label = controller.categoryTypeLabel;
              final available = controller.availableCategoryTypes;
              final selected = controller.selectedCategoryTypes;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.golden.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.golden.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sell_outlined, size: 20, color: AppColors.golden),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyBlue,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showAddCustomTypeDialog(context, controller),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Other', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.navyBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select all types/flavours/offerings you provide and specify price (₹) for each:',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),

                    // Chips for available + custom types
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...available.map((type) {
                          final isSelected = selected.contains(type);
                          return FilterChip(
                            label: Text(type),
                            selected: isSelected,
                            selectedColor: AppColors.golden.withValues(alpha: 0.35),
                            checkmarkColor: AppColors.navyBlue,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.navyBlue : Colors.black87,
                            ),
                            onSelected: (_) => controller.toggleCategoryType(type),
                          );
                        }),
                        // Render any custom types that aren't in available
                        ...selected.where((t) => !available.contains(t)).map((customType) {
                          return FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(customType),
                                const SizedBox(width: 4),
                                const Icon(Icons.stars, size: 12, color: AppColors.golden),
                              ],
                            ),
                            selected: true,
                            selectedColor: AppColors.golden.withValues(alpha: 0.35),
                            checkmarkColor: AppColors.navyBlue,
                            labelStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyBlue,
                            ),
                            onSelected: (_) => controller.toggleCategoryType(customType),
                          );
                        }),
                      ],
                    ),

                    // Price input for each selected type
                    if (selected.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Text(
                        'Set Price (₹) for Selected Offerings:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...selected.map((type) {
                        final priceCtrl = controller.typePriceControllers[type];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  type,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: priceCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    prefixText: '₹ ',
                                    hintText: 'Rate / Price',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        '⚠️ Please select at least one type/offering above to set your rates.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),


            // Rental / Space Type Dropdown
            if (controller.isFieldEnabled('timings')) ...[
              _buildLabelWithAsterisk('Rental Type / Booking Model'),
              DropdownButtonFormField<int>(
                initialValue: controller.selectedSpaceType.value,
                decoration: const InputDecoration(hintText: 'Select Rental Type'),
                items: const [
                  DropdownMenuItem<int>(value: 1, child: Text('Fixed Timeslot')),
                  DropdownMenuItem<int>(value: 2, child: Text('Hourly')),
                  DropdownMenuItem<int>(value: 3, child: Text('Multi Day')),
                ],
                onChanged: (val) => controller.selectedSpaceType.value = val ?? 1,
              ),
              const SizedBox(height: 16),
            ],

            // Guest capacity
            if (controller.isFieldEnabled('guests')) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelWithAsterisk('Min Guest Capacity'),
                        TextFormField(
                          controller: controller.minGuestController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'e.g. 50'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelWithAsterisk('Max Guest Capacity'),
                        TextFormField(
                          controller: controller.maxGuestController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'e.g. 500'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Space Size
            if (controller.isFieldEnabled('space_size')) ...[
              _buildLabelWithAsterisk(controller.fieldLabel('space_size', 'Space Size (Sq. Ft.)')),
              TextFormField(
                controller: controller.sizeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'e.g. 2500'),
              ),
              const SizedBox(height: 16),
            ],

            // Render Dynamic Custom Fields
            if (controller.customFields.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Additional Features & Attributes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              ...controller.customFields.map((entry) {
                final ctrl = controller.customFieldControllers[entry.key];
                final options = controller.getDropdownOptions(entry.key);
                final isNumber = entry.key.contains('experience') || entry.key.contains('price') || entry.key.contains('charge') || entry.key.contains('size');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabelWithAsterisk(entry.value, isRequired: controller.isCustomFieldRequired(entry.key)),
                      if (options != null)
                        DropdownButtonFormField<String>(
                          value: (ctrl != null && ctrl.text.isNotEmpty && options.contains(ctrl.text)) ? ctrl.text : null,
                          decoration: InputDecoration(hintText: 'Select ${entry.value}'),
                          items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                          onChanged: (val) {
                            if (ctrl != null && val != null) ctrl.text = val;
                          },
                        )
                      else
                        TextFormField(
                          controller: ctrl,
                          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
                          decoration: InputDecoration(hintText: 'Enter ${entry.value}'),
                        ),
                    ],
                  ),
                );
              }),
            ],

            // Amenities Selection
            if (controller.isFieldEnabled('amenities') && controller.amenities.isNotEmpty) ...[
              const Divider(height: 24),
              _buildLabelWithAsterisk('Select Amenities / Facilities'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.amenities.map((amenity) {
                  final id = amenity['id'] as int;
                  final name = amenity['name']?.toString() ?? '';
                  final isSelected = controller.selectedAmenities.contains(id);
                  return FilterChip(
                    label: Text(name),
                    selected: isSelected,
                    selectedColor: AppColors.golden.withValues(alpha: 0.3),
                    checkmarkColor: AppColors.navyBlue,
                    onSelected: (_) => controller.toggleAmenity(id),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 3: IMAGES & VIDEOS
  // -------------------------------------------------------------
  Widget _buildStep3ImagesAndVideos(BuildContext context, AddSpaceController controller) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Step 3: Photos & Videos'),
            const SizedBox(height: 16),

            // Thumbnail Image *
            _buildLabelWithAsterisk('Thumbnail Image (Main Preview)', isRequired: true),
            const SizedBox(height: 8),
            _buildSinglePickerBox(
              label: 'Upload Thumbnail Image',
              selectedFile: controller.selectedThumbnailImage.value,
              existingUrl: controller.existingThumbnailUrl.value,
              onTap: () => controller.pickThumbnailImage(context),
              onRemove: () => controller.selectedThumbnailImage.value = null,
            ),
            const SizedBox(height: 20),

            // Cover Image
            _buildLabelWithAsterisk('Cover Image (Header Banner)'),
            const SizedBox(height: 8),
            _buildSinglePickerBox(
              label: 'Upload Cover Image',
              selectedFile: controller.selectedCoverImage.value,
              existingUrl: controller.existingCoverUrl.value,
              onTap: () => controller.pickCoverImage(context),
              onRemove: () => controller.selectedCoverImage.value = null,
            ),
            const SizedBox(height: 20),

            // Gallery Images (Max 20)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabelWithAsterisk('Gallery Images'),
                Obx(() => Text(
                  '${controller.selectedGalleryImages.length + controller.existingGalleryUrls.length} / 20',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyBlue),
                )),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: controller.pickGalleryImages,
              icon: const Icon(Icons.add_a_photo, size: 18),
              label: const Text('Add Gallery Photos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyBlue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildGalleryGrid(controller),

            const SizedBox(height: 24),
            // Videos (Max 5)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabelWithAsterisk('Video Uploads'),
                Obx(() => Text(
                  '${controller.selectedVideos.length + controller.existingVideoUrls.length} / 5',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyBlue),
                )),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: controller.pickVideo,
              icon: const Icon(Icons.videocam, size: 18),
              label: const Text('Add Video File'),
            ),
            const SizedBox(height: 12),
            _buildVideosList(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildSinglePickerBox({
    required String label,
    required XFile? selectedFile,
    required String? existingUrl,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: selectedFile != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(File(selectedFile.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.white),
                        onPressed: onRemove,
                      ),
                    ),
                  ),
                ],
              )
            : existingUrl != null
                ? Image.network(existingUrl, fit: BoxFit.cover)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.navyBlue),
                      const SizedBox(height: 8),
                      Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildGalleryGrid(AddSpaceController controller) {
    return Obx(() {
      final total = controller.selectedGalleryImages.length + controller.existingGalleryUrls.length;
      if (total == 0) return const SizedBox.shrink();

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: total,
        itemBuilder: (context, index) {
          if (index < controller.selectedGalleryImages.length) {
            final file = controller.selectedGalleryImages[index];
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(file.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => controller.removeGalleryImage(index),
                    child: const CircleAvatar(backgroundColor: Colors.black54, radius: 12, child: Icon(Icons.close, size: 14, color: Colors.white)),
                  ),
                ),
              ],
            );
          } else {
            final existingIndex = index - controller.selectedGalleryImages.length;
            final url = controller.existingGalleryUrls[existingIndex];
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => controller.removeExistingGalleryImage(existingIndex),
                    child: const CircleAvatar(backgroundColor: Colors.black54, radius: 12, child: Icon(Icons.close, size: 14, color: Colors.white)),
                  ),
                ),
              ],
            );
          }
        },
      );
    });
  }

  Widget _buildVideosList(AddSpaceController controller) {
    return Obx(() {
      final total = controller.selectedVideos.length + controller.existingVideoUrls.length;
      if (total == 0) return const SizedBox.shrink();

      return Column(
        children: List.generate(total, (index) {
          final isSelected = index < controller.selectedVideos.length;
          final fileName = isSelected
              ? controller.selectedVideos[index].name
              : controller.existingVideoUrls[index - controller.selectedVideos.length].split('/').last;

          final filePath = isSelected ? controller.selectedVideos[index].path : null;
          final networkUrl = isSelected ? null : controller.existingVideoUrls[index - controller.selectedVideos.length];

          return _VendorVideoPreviewTile(
            key: ValueKey(filePath ?? networkUrl ?? index.toString()),
            fileName: fileName,
            filePath: filePath,
            networkUrl: networkUrl,
            isSelected: isSelected,
            onDelete: () {
              if (isSelected) {
                controller.removeVideo(index);
              } else {
                controller.removeExistingVideo(index - controller.selectedVideos.length);
              }
            },
          );
        }),
      );
    });
  }

  // -------------------------------------------------------------
  // STEP 4: DOCUMENTS
  // -------------------------------------------------------------
  Widget _buildStep4Documents(BuildContext context, AddSpaceController controller) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Step 4: Business Documents'),
            const SizedBox(height: 16),

            _buildDocPickerRow(context, 'Aadhaar Card (Front Side) *', controller.aadhaarFrontDoc, controller.existingAadhaarFrontUrl, controller, isRequired: true),
            const SizedBox(height: 16),

            _buildDocPickerRow(context, 'Aadhaar Card (Back Side) *', controller.aadhaarBackDoc, controller.existingAadhaarBackUrl, controller, isRequired: true),
            const SizedBox(height: 16),

            _buildDocPickerRow(context, 'PAN Card *', controller.panDoc, controller.existingPanUrl, controller, isRequired: true),
            const SizedBox(height: 16),

            _buildDocPickerRow(context, 'Business Proof', controller.businessProofDoc, controller.existingBusinessProofUrl, controller),
            const SizedBox(height: 16),

            _buildDocPickerRow(context, 'GST Certificate (Optional)', controller.gstDoc, controller.existingGstUrl, controller),
            const SizedBox(height: 16),

            _buildDocPickerRow(context, 'Shop License (Optional)', controller.shopLicenseDoc, controller.existingShopLicenseUrl, controller),
            const SizedBox(height: 16),

            _buildDocPickerRow(context, 'Address Proof', controller.addressProofDoc, controller.existingAddressProofUrl, controller),
            const SizedBox(height: 16),

            _buildDocPickerRow(context, 'Cancelled Cheque / Bank Proof', controller.chequeDoc, controller.existingChequeUrl, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildDocPickerRow(
    BuildContext context,
    String label,
    Rxn<XFile> fileRx,
    RxnString urlRx,
    AddSpaceController controller, {
    bool isRequired = false,
  }) {
    return Obx(() {
      final file = fileRx.value;
      final url = urlRx.value;
      final hasDoc = file != null || (url != null && url.isNotEmpty);

      Widget previewWidget;
      if (file != null) {
        previewWidget = ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(File(file.path), width: 44, height: 44, fit: BoxFit.cover),
        );
      } else if (url != null && url.isNotEmpty) {
        previewWidget = ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(url, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 24, color: Colors.grey)),
        );
      } else {
        previewWidget = Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
          child: const Icon(Icons.description_outlined, color: Colors.grey, size: 24),
        );
      }

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: hasDoc ? AppColors.success : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            previewWidget,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabelWithAsterisk(label, isRequired: isRequired),
                  Text(
                    file != null ? file.name : (hasDoc ? 'Uploaded' : 'Not Uploaded'),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => controller.pickDocument(context, fileRx),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasDoc ? Colors.grey.shade200 : AppColors.navyBlue,
                foregroundColor: hasDoc ? Colors.black87 : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: Text(hasDoc ? 'Change' : 'Upload', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    });
  }

  // -------------------------------------------------------------
  // STEP 5: BUSINESS SETTINGS (TIMINGS)
  // -------------------------------------------------------------
  Widget _buildStep5BusinessSettings(BuildContext context, AddSpaceController controller) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildSectionHeader('Step 5: Business Hours & Timings'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: controller.copyMondayTimingToAllDays,
                  icon: const Icon(Icons.copy, size: 14, color: AppColors.navyBlue),
                  label: const Text('Copy Monday', style: TextStyle(fontSize: 11, color: AppColors.navyBlue)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    side: const BorderSide(color: AppColors.navyBlue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...days.map((day) {
              return Obx(() {
                final timing = controller.weeklyTimings[day]!;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: timing.isWeeklyOff ? Colors.grey.shade100 : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 80, child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      Switch(
                        value: !timing.isWeeklyOff,
                        activeTrackColor: AppColors.golden,
                        onChanged: (val) {
                          timing.isWeeklyOff = !val;
                          controller.weeklyTimings.refresh();
                        },
                      ),
                      Text(timing.isWeeklyOff ? 'OFF' : 'OPEN', style: TextStyle(fontSize: 12, color: timing.isWeeklyOff ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              });
            }),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 6: BOOKING SETTINGS
  // -------------------------------------------------------------
  Widget _buildStep6BookingSettings(BuildContext context, AddSpaceController controller) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Step 6: Booking & Cancellation Policies'),
            const SizedBox(height: 16),

            _buildLabelWithAsterisk('Cancellation Policy'),
            TextFormField(
              controller: controller.cancellationPolicyController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'e.g. Free cancellation up to 48 hours before event'),
            ),
            const SizedBox(height: 16),

            _buildLabelWithAsterisk('Refund Policy'),
            TextFormField(
              controller: controller.refundPolicyController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'e.g. 80% refund if cancelled 7 days prior'),
            ),
            const SizedBox(height: 20),

            Obx(() => SwitchListTile(
              title: const Text('Enable Instant Booking'),
              subtitle: const Text('Customers can book without waiting for manual confirmation'),
              value: controller.instantBookingEnabled.value,
              activeColor: AppColors.golden,
              onChanged: (val) => controller.instantBookingEnabled.value = val,
            )),
            Obx(() => SwitchListTile(
              title: const Text('Enable WhatsApp Inquiry'),
              subtitle: const Text('Allow direct inquiries via WhatsApp'),
              value: controller.whatsappBookingEnabled.value,
              activeColor: AppColors.golden,
              onChanged: (val) => controller.whatsappBookingEnabled.value = val,
            )),
            Obx(() => SwitchListTile(
              title: const Text('Enable Call Booking'),
              subtitle: const Text('Allow direct phone call inquiries'),
              value: controller.callBookingEnabled.value,
              activeColor: AppColors.golden,
              onChanged: (val) => controller.callBookingEnabled.value = val,
            )),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 7: REVIEW & SUBMIT
  // -------------------------------------------------------------
  Widget _buildStep7ReviewAndSubmit(BuildContext context, AddSpaceController controller) {
    return Column(
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Step 7: Review & Final Submission'),
                const SizedBox(height: 16),

                _buildSummarySection('Basic Information', [
                  _buildDetailRow('Space Title', controller.titleController.text),
                  _buildDetailRow('Business Name', controller.businessNameController.text),
                  _buildDetailRow('Mobile Number', controller.mobileController.text),
                  _buildDetailRow('WhatsApp', controller.whatsappController.text),
                  _buildDetailRow('Email', controller.emailController.text),
                  _buildDetailRow('City', controller.cityController.text),
                  _buildDetailRow('Area', controller.areaController.text),
                  _buildDetailRow('Address', controller.addressController.text),
                ], () => controller.goToStep(0)),

                _buildSummarySection('Category Details', [
                  if (controller.isFieldEnabled('guests'))
                    _buildDetailRow('Guests Capacity', '${controller.minGuestController.text} to ${controller.maxGuestController.text}'),
                  if (controller.isFieldEnabled('space_size'))
                    _buildDetailRow('Space Size', '${controller.sizeController.text} sq.ft'),
                  if (controller.selectedCategoryTypes.isNotEmpty)
                    _buildDetailRow(
                      'Services & Pricing',
                      controller.selectedCategoryTypes
                          .map((t) => '$t: ₹${controller.typePriceControllers[t]?.text ?? "0"}')
                          .join(', '),
                    ),
                  ...controller.customFields.map((entry) => 
                    _buildDetailRow(entry.value, controller.customFieldControllers[entry.key]?.text ?? '')
                  ),
                ], () => controller.goToStep(1)),

                _buildSummarySection('Media & Documents', [
                  _buildDetailRow('Photos', '${controller.selectedGalleryImages.length + controller.existingGalleryUrls.length} Uploaded'),
                  _buildDetailRow('Videos', '${controller.selectedVideos.length + controller.existingVideoUrls.length} Uploaded'),
                  _buildDetailRow('Aadhaar Card', controller.aadhaarDoc.value != null || controller.existingAadhaarUrl.value != null ? 'Uploaded' : 'Pending'),
                  _buildDetailRow('PAN Card', controller.panDoc.value != null || controller.existingPanUrl.value != null ? 'Uploaded' : 'Pending'),
                  _buildDetailRow('Business Proof', controller.businessProofDoc.value != null || controller.existingBusinessProofUrl.value != null ? 'Uploaded' : 'N/A'),
                ], () => controller.goToStep(2)), // Note: Step 2 and 3 are combined conceptually in review

                _buildSummarySection('Business Timings', [
                  ...['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'].map((day) {
                    final t = controller.weeklyTimings[day]!;
                    return _buildDetailRow(day, t.isWeeklyOff ? 'OFF' : 'OPEN');
                  }),
                ], () => controller.goToStep(4)),

                _buildSummarySection('Booking Settings', [
                  _buildDetailRow('Cancellation Policy', controller.cancellationPolicyController.text),
                  _buildDetailRow('Refund Policy', controller.refundPolicyController.text),
                  _buildDetailRow('Instant Booking', controller.instantBookingEnabled.value ? 'Yes' : 'No'),
                  _buildDetailRow('WhatsApp Inquiry', controller.whatsappBookingEnabled.value ? 'Yes' : 'No'),
                  _buildDetailRow('Call Booking', controller.callBookingEnabled.value ? 'Yes' : 'No'),
                ], () => controller.goToStep(5)),

                const Divider(height: 32),

                Obx(() => CheckboxListTile(
                  title: const Text('I agree to the Terms & Conditions and confirm all provided information is accurate.', style: TextStyle(fontSize: 12)),
                  value: controller.acceptedTerms.value,
                  activeColor: AppColors.navyBlue,
                  onChanged: (val) => controller.acceptedTerms.value = val ?? false,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(String title, List<Widget> details, VoidCallback onEdit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyBlue)),
              InkWell(
                onTap: onEdit,
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.edit, size: 16, color: AppColors.golden),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...details,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12))),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black87))),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // BOTTOM NAVIGATION BAR
  // -------------------------------------------------------------
  Widget _buildBottomNav(BuildContext context, AddSpaceController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (controller.currentStep.value > 0)
            OutlinedButton.icon(
              onPressed: controller.previousStep,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('PREVIOUS'),
            )
          else
            const SizedBox.shrink(),

          ElevatedButton.icon(
            onPressed: controller.isLoading.value ? null : controller.nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: controller.isLoading.value
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(controller.currentStep.value == 6 ? Icons.check_circle : Icons.arrow_forward, size: 18),
            label: Text(controller.currentStep.value == 6 ? 'SUBMIT SPACE' : 'CONTINUE'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.navyBlue),
    );
  }

  Widget _buildLabelWithAsterisk(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
          children: [
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomTypeDialog(BuildContext context, AddSpaceController controller) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Add Custom Item / Service', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter item or service name:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. Ferrero Rocher, Candid Drone',
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            const Text('Price (₹):', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '₹ ',
                hintText: 'e.g. 750',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.golden,
              foregroundColor: AppColors.navyBlue,
            ),
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                controller.addCustomCategoryType(name, initialPrice: priceCtrl.text.trim());
                Get.back();
              }
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }
}


class _VendorVideoPreviewTile extends StatefulWidget {
  final String fileName;
  final String? filePath;
  final String? networkUrl;
  final bool isSelected;
  final VoidCallback onDelete;

  const _VendorVideoPreviewTile({
    super.key,
    required this.fileName,
    this.filePath,
    this.networkUrl,
    required this.isSelected,
    required this.onDelete,
  });

  @override
  State<_VendorVideoPreviewTile> createState() => _VendorVideoPreviewTileState();
}

class _VendorVideoPreviewTileState extends State<_VendorVideoPreviewTile> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() async {
    try {
      if (widget.filePath != null) {
        _controller = VideoPlayerController.file(File(widget.filePath!));
      } else if (widget.networkUrl != null && widget.networkUrl!.isNotEmpty) {
        String url = widget.networkUrl!;
        if (!url.startsWith('http')) {
          final s = url.replaceAll(RegExp(r'^/+|/+$'), '');
          url = 'https://bookwithkhushi.com/assets/img/spaces/slider/$s';
        }
        _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      }
      if (_controller != null) {
        await _controller!.initialize();
        _controller!.setLooping(true);
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _controller?.value.isPlaying ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Live Video Container Frame
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isInitialized && _controller != null)
                    AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    )
                  else
                    Container(
                      color: Colors.black87,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  // Dark Overlay gradient for contrast
                  Container(
                    color: isPlaying ? Colors.transparent : Colors.black38,
                  ),
                  // Interactive Play / Pause Overlay Icon Button
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.navyBlue.withOpacity(0.85),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Info Row with File details & Delete Icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isPlaying ? Icons.videocam : Icons.videocam_outlined,
                  color: AppColors.navyBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPlaying ? '▶ Video Playing' : '⏸ Video Paused (Tap to play)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isPlaying ? Colors.green.shade700 : Colors.grey.shade600,
                          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 22),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
