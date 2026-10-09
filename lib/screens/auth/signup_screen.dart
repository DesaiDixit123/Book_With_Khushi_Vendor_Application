import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';
import '../../constants/app_colors.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller is already initialized in LoginScreen, but using find just in case
    final controller = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Registration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.navyBlue,
        iconTheme: const IconThemeData(color: AppColors.navyBlue),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: controller.signupFormKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create an Account',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join BookWithKhushi as a Partner',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: controller.signupNameController,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.badge)),
                    validator: (value) => value!.isEmpty ? 'Please enter full name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller.signupUsernameController,
                    decoration: InputDecoration(
                      labelText: 'Username', 
                      prefixIcon: const Icon(Icons.person),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.maroon),
                        onPressed: () => controller.refreshUsername(),
                        tooltip: 'Regenerate Username',
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? 'Please enter username' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller.signupEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
                    validator: (value) {
                      if (value!.isEmpty) return 'Please enter email';
                      if (!GetUtils.isEmail(value)) return 'Please enter valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller.signupPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
                    validator: (value) => value!.isEmpty ? 'Please enter phone number' : null,
                  ),
                  const SizedBox(height: 16),
                  Obx(() => TextFormField(
                    controller: controller.signupPasswordController,
                    obscureText: controller.isSignupPasswordObscure.value,
                    decoration: InputDecoration(
                      labelText: 'Password', 
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isSignupPasswordObscure.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textGrey,
                        ),
                        onPressed: () => controller.isSignupPasswordObscure.value =
                            !controller.isSignupPasswordObscure.value,
                      ),
                    ),
                    validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
                  )),
                  const SizedBox(height: 16),
                  Obx(() => TextFormField(
                    controller: controller.signupConfirmPasswordController,
                    obscureText: controller.isSignupConfirmPasswordObscure.value,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password', 
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isSignupConfirmPasswordObscure.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textGrey,
                        ),
                        onPressed: () => controller.isSignupConfirmPasswordObscure.value =
                            !controller.isSignupConfirmPasswordObscure.value,
                      ),
                    ),
                    validator: (value) {
                      if (value != controller.signupPasswordController.text) return 'Passwords do not match';
                      return null;
                    },
                  )),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller.signupReferralCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Referral Code (Optional)',
                      prefixIcon: Icon(Icons.card_giftcard),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Obx(() => ElevatedButton(
                    onPressed: controller.isSignupLoading.value ? null : () => controller.signup(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: controller.isSignupLoading.value
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('SIGN UP'),
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
