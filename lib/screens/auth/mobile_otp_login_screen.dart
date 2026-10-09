import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'mobile_otp_controller.dart';
import '../../constants/app_colors.dart';

class MobileOtpLoginScreen extends StatelessWidget {
  const MobileOtpLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MobileOtpController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner OTP Login'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.navyBlue,
        iconTheme: const IconThemeData(color: AppColors.navyBlue),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Obx(() {
              if (!controller.otpSent.value) {
                // STEP 1: Enter phone number
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Login with Mobile',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We will send an OTP to verify your mobile number',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: controller.phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: Icon(Icons.phone),
                        hintText: 'Enter 10-digit number',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: controller.isSendingOtp.value
                          ? null
                          : () => controller.sendOtp(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: controller.isSendingOtp.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('SEND OTP'),
                    ),
                  ],
                );
              } else {
                // STEP 2: Enter OTP
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Enter OTP',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'OTP sent to +91 ${controller.phoneNumber.value}',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: controller.otpController,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      decoration: const InputDecoration(
                        labelText: 'One-Time Password',
                        prefixIcon: Icon(Icons.lock_person),
                        hintText: 'Enter 6-digit OTP',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: controller.isVerifying.value
                          ? null
                          : () => controller.verifyOtp(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: controller.isVerifying.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('VERIFY & LOGIN'),
                    ),
                     const SizedBox(height: 20),
                     Obx(() {
                       final seconds = controller.secondsRemaining.value;
                       final isTimerActive = seconds > 0;
                       return Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Text(
                             isTimerActive
                                 ? "Resend OTP in ${seconds}s"
                                 : "Didn't receive the OTP?",
                             style: TextStyle(
                               color: Colors.grey.shade600,
                               fontSize: 14,
                             ),
                           ),
                           if (!isTimerActive)
                             TextButton(
                               onPressed: () => controller.sendOtp(),
                               child: const Text(
                                 'Resend OTP',
                                 style: TextStyle(
                                   color: AppColors.maroon,
                                   fontWeight: FontWeight.bold,
                                 ),
                               ),
                             ),
                         ],
                       );
                     }),
                     const SizedBox(height: 12),
                     TextButton(
                       onPressed: () => controller.resetToPhoneEntry(),
                       child: const Text('Change Phone Number'),
                     ),
                  ],
                );
              }
            }),
          ),
        ),
      ),
    );
  }
}
