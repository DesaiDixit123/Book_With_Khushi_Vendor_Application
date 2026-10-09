import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../constants/app_colors.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuthController());

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: controller.loginFormKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/bookwithkhushi_logo_transparent.png',
                    height: 120,
                    width: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Login to manage your spaces',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: controller.loginUsernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username or Email',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) => value!.isEmpty ? 'Please enter username' : null,
                  ),
                  const SizedBox(height: 16),
                  Obx(() => TextFormField(
                    controller: controller.loginPasswordController,
                    obscureText: controller.isLoginPasswordObscure.value,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isLoginPasswordObscure.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textGrey,
                        ),
                        onPressed: () => controller.isLoginPasswordObscure.value =
                            !controller.isLoginPasswordObscure.value,
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? 'Please enter password' : null,
                  )),
                  const SizedBox(height: 8),
                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Get.to(() => const ForgotPasswordScreen()),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.navyBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(() => ElevatedButton(
                    onPressed: controller.isLoginLoading.value ? null : () => controller.login(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: controller.isLoginLoading.value
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('LOGIN'),
                  )),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.signup),
                    child: const Text('Don\'t have an account? Sign up'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(color: Colors.grey)),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Get.toNamed(AppRoutes.mobileOtpLogin),
                    icon: const Icon(Icons.phone_android, color: AppColors.maroon),
                    label: const Text(
                      'LOGIN WITH MOBILE NUMBER',
                      style: TextStyle(color: AppColors.maroon, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.maroon),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
