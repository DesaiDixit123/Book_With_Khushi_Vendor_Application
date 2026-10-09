import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'change_password_controller.dart';
import '../../widgets/app_drawer.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChangePasswordController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Obx(() => TextFormField(
                controller: controller.currentPasswordController,
                obscureText: controller.isCurrentPasswordObscure.value,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isCurrentPasswordObscure.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => controller.isCurrentPasswordObscure.value =
                        !controller.isCurrentPasswordObscure.value,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter current password';
                  }
                  return null;
                },
              )),
              const SizedBox(height: 16),
              Obx(() => TextFormField(
                controller: controller.newPasswordController,
                obscureText: controller.isNewPasswordObscure.value,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isNewPasswordObscure.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => controller.isNewPasswordObscure.value =
                        !controller.isNewPasswordObscure.value,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              )),
              const SizedBox(height: 16),
              Obx(() => TextFormField(
                controller: controller.confirmPasswordController,
                obscureText: controller.isConfirmPasswordObscure.value,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isConfirmPasswordObscure.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => controller.isConfirmPasswordObscure.value =
                        !controller.isConfirmPasswordObscure.value,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please confirm new password';
                  }
                  if (value != controller.newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              )),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.changePassword,
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('UPDATE PASSWORD'),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
