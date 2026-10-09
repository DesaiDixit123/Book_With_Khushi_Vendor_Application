import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'profile_controller.dart';
import '../../constants/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../routes/app_routes.dart';
import '../../utils/snackbar_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ProfileController>();
    // If data already loaded, refresh silently in background (no spinner)
    // If data not loaded yet, show spinner and fetch
    controller.fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: controller.fetchProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            _buildProfileImagePicker(),
            const SizedBox(height: 24),
            _buildFormFields(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Obx(() => ElevatedButton(
                onPressed: controller.isSaving.value ? null : controller.updateProfile,
                child: controller.isSaving.value
                    ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('SAVE PROFILE'),
              )),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteAccountDialog(),
                icon: const Icon(Icons.delete_forever, size: 20),
                label: const Text('DELETE ACCOUNT'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
    );
  }

  void _showDeleteAccountDialog() {
    Get.defaultDialog(
      title: 'Delete Account',
      titleStyle: const TextStyle(color: AppColors.navyBlue, fontWeight: FontWeight.bold),
      middleText: 'Are you sure you want to permanently delete your account?\n\nThis action CANNOT be undone. All your data will be lost.',
      middleTextStyle: const TextStyle(fontSize: 14, color: Colors.black54),
      textConfirm: 'Yes, Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.error,
      onConfirm: () async {
        Get.back();
        await _performDeleteAccount();
      },
    );
  }

  Future<void> _performDeleteAccount() async {
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: AppColors.maroon)),
      barrierDismissible: false,
    );

    try {
      final apiService = Get.find<ApiService>();
      final storageService = Get.find<StorageService>();

      final response = await apiService.dio.post('/user/delete');

      if (Get.isDialogOpen ?? false) Get.back();

      if (response.data['status'] == true) {
        await storageService.removeToken();
        Get.offAllNamed(AppRoutes.login);
        SnackbarHelper.showSuccess('Your account has been permanently deleted.');
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Failed to delete account.');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      SnackbarHelper.showError('Failed to delete account. Please try again.');
    }
  }

  Widget _buildProfileImagePicker() {
    return GestureDetector(
      onTap: controller.pickImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Obx(() => Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              border: Border.all(color: AppColors.navyBlue, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyBlue.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: controller.selectedImage.value != null
                  ? Image.file(File(controller.selectedImage.value!.path), fit: BoxFit.cover)
                  : controller.profileImageUrl.value != null
                      ? CachedNetworkImage(
                          imageUrl: controller.profileImageUrl.value!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Icon(Icons.person, size: 60, color: Colors.grey),
                          errorWidget: (context, url, error) => const Icon(Icons.person, size: 60, color: Colors.grey),
                        )
                      : const Icon(Icons.person, size: 60, color: Colors.grey),
            ),
          )),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.maroon,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextFormField(
          controller: controller.nameController,
          decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.addressController,
          decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.cityController,
                decoration: const InputDecoration(labelText: 'City'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: controller.stateController,
                decoration: const InputDecoration(labelText: 'State'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.countryController,
                decoration: const InputDecoration(labelText: 'Country'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: controller.zipController,
                decoration: const InputDecoration(labelText: 'Zip Code'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.detailsController,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'About You (Details)', alignLabelWithHint: true),
        ),
      ],
    );
  }
}
