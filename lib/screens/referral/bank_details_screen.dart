import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import 'referral_controller.dart';

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final VendorReferralController controller = Get.put(VendorReferralController());

  @override
  void initState() {
    super.initState();
    controller.fetchBankDetails();
  }

  @override
  Widget build(BuildContext context) {
    final siteUrl = Get.find<ApiService>().baseUrl.replaceAll('/api', '/');
    final upperCaseFormatter = TextInputFormatter.withFunction(
      (oldVal, newVal) => newVal.copyWith(text: newVal.text.toUpperCase()),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text("Bank Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Configure Bank Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyBlue),
            ),
            const SizedBox(height: 4),
            Text(
              "For receiving direct cash payouts.",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller.accountHolderController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [upperCaseFormatter],
              decoration: const InputDecoration(
                labelText: "Account Holder Name",
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.bankNameController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [upperCaseFormatter],
              decoration: const InputDecoration(
                labelText: "Bank Name",
                prefixIcon: Icon(Icons.account_balance),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.branchNameController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [upperCaseFormatter],
              decoration: const InputDecoration(
                labelText: "Branch Name",
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.accountNumberController,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: "Account Number",
                prefixIcon: Icon(Icons.password),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.confirmAccountNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: "Confirm Account Number",
                prefixIcon: Icon(Icons.password),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.ifscCodeController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [upperCaseFormatter],
              decoration: const InputDecoration(
                labelText: "IFSC Code",
                prefixIcon: Icon(Icons.code),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.upiIdController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [upperCaseFormatter],
              decoration: const InputDecoration(
                labelText: "UPI ID (Optional)",
                prefixIcon: Icon(Icons.qr_code_2),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Cancelled Cheque / Passbook Image *",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final localImage = controller.selectedPassbookImage.value;
              final networkImageUrl = controller.passbookImageUrl.value;

              return InkWell(
                onTap: () => controller.pickPassbookImage(),
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: localImage != null
                        ? Image.file(
                            localImage,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          )
                        : networkImageUrl.isNotEmpty
                            ? Image.network(
                                "$siteUrl$networkImageUrl",
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey));
                                },
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.navyBlue),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Tap to upload Cancelled Cheque",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "(Max size 2MB, JPG/PNG)",
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
            Obx(() => ElevatedButton(
              onPressed: controller.isSavingBank.value
                  ? null
                  : () async {
                      if (controller.accountHolderController.text.trim().isEmpty ||
                          controller.bankNameController.text.trim().isEmpty ||
                          controller.branchNameController.text.trim().isEmpty ||
                          controller.accountNumberController.text.trim().isEmpty ||
                          controller.confirmAccountNumberController.text.trim().isEmpty ||
                          controller.ifscCodeController.text.trim().isEmpty) {
                        Get.snackbar("Error", "Please fill in all required fields",
                            backgroundColor: AppColors.error, colorText: Colors.white);
                        return;
                      }
                      if (controller.accountNumberController.text.trim() !=
                          controller.confirmAccountNumberController.text.trim()) {
                        Get.snackbar("Error", "Account numbers do not match",
                            backgroundColor: AppColors.error, colorText: Colors.white);
                        return;
                      }
                      if (controller.selectedPassbookImage.value == null &&
                          controller.passbookImageUrl.value.isEmpty) {
                        Get.snackbar("Error", "Please upload a Cancelled Cheque / Passbook Image",
                            backgroundColor: AppColors.error, colorText: Colors.white);
                        return;
                      }
                      final success = await controller.saveBankDetails();
                      if (success) {
                        Get.back();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyBlue,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: controller.isSavingBank.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save Bank Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            )),
          ],
        ),
      ),
    );
  }
}
