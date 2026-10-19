import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../widgets/app_drawer.dart';
import 'referral_controller.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final VendorReferralController controller = Get.put(VendorReferralController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refer & Earn'),
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.fetchReferralData();
          await controller.fetchReferralHistory();
        },
        color: AppColors.navyBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Burgundy Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.navyBlue, AppColors.maroon],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navyBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(Icons.share_arrival_time_outlined, size: 54, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      "Grow the Travel network!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Refer other vendors to Khushi Holidays. Earn reward points once they successfully subscribe to packages.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Code Display Card
              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30.0),
                      child: CircularProgressIndicator(color: AppColors.navyBlue),
                    ),
                  );
                }

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          "YOUR REFERRAL CODE",
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          controller.referralCode.value.isNotEmpty ? controller.referralCode.value : "LOADING...",
                          style: const TextStyle(fontSize: 28, color: AppColors.navyBlue, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (controller.referralCode.value.isNotEmpty) {
                              Clipboard.setData(ClipboardData(text: controller.referralCode.value));
                              Get.snackbar("Copied", "Referral code copied!", backgroundColor: AppColors.success, colorText: Colors.white);
                            }
                          },
                          icon: const Icon(Icons.copy, size: 16, color: Colors.white),
                          label: const Text("Copy Code", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navyBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Share via:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildShareChip(
                              label: "WhatsApp",
                              color: const Color(0xFF25D366),
                              icon: Icons.chat,
                              onTap: () => _shareWhatsApp(controller.shareMessage.value, controller.referralCode.value),
                            ),
                            _buildShareChip(
                              label: "SMS",
                              color: const Color(0xFF007AFF),
                              icon: Icons.textsms_outlined,
                              onTap: () => _shareSMS(controller.shareMessage.value, controller.referralCode.value),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Stats row
              Obx(() {
                if (controller.isLoading.value) return const SizedBox();

                return Row(
                  children: [
                    Expanded(child: _buildStatCard("Total Invites", controller.totalReferrals.value.toString(), AppColors.navyBlue)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatCard("Subscribed", controller.successfulReferrals.value.toString(), AppColors.success)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatCard("Points Earned", controller.totalEarned.value.toString(), AppColors.golden)),
                  ],
                );
              }),

              const SizedBox(height: 24),

              // History list
              const Text(
                "Recent Vendor Joins",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Obx(() {
                if (controller.isHistoryLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: AppColors.navyBlue),
                    ),
                  );
                }

                if (controller.referralHistory.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    alignment: Alignment.center,
                    child: const Column(
                      children: [
                        Icon(Icons.people_outline, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("No vendor referrals signed up yet.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.referralHistory.length,
                  itemBuilder: (context, index) {
                    final item = controller.referralHistory[index];
                    final isCompleted = item['status'].toString().toLowerCase() == 'completed';
                    return Card(
                      elevation: 0.5,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        title: Text(
                          item['referral_name'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text("Joined: ${item['registration_date']?.split(' ')[0] ?? ''}", style: const TextStyle(fontSize: 12)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isCompleted ? "+${item['reward_earned']} Pts" : "Pending",
                              style: TextStyle(fontWeight: FontWeight.bold, color: isCompleted ? AppColors.success : AppColors.warning),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: isCompleted ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item['status'] ?? 'Pending',
                                style: TextStyle(fontSize: 9, color: isCompleted ? AppColors.success : AppColors.maroon, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareChip({required String label, required Color color, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Future<void> _shareWhatsApp(String shareMsg, String code) async {
    final msg = shareMsg.isNotEmpty
        ? shareMsg
        : "Join Book with Khushi Partner as a Vendor using my referral code: $code\n\n"
            "🤖 Android Play Store: https://play.google.com/store/apps/details?id=com.bookwithkhushipartner\n"
            "🍎 iOS App Store: https://apps.apple.com/app/id6774184822";
    final encoded = Uri.encodeComponent(msg);
    final waUri = Uri.parse("whatsapp://send?text=$encoded");
    try {
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
      } else {
        final webUri = Uri.parse("https://api.whatsapp.com/send?text=$encoded");
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      final webUri = Uri.parse("https://api.whatsapp.com/send?text=$encoded");
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareSMS(String shareMsg, String code) async {
    final msg = shareMsg.isNotEmpty
        ? shareMsg
        : "Join Book with Khushi Partner as a Vendor using my referral code: $code\n\n"
            "🤖 Android Play Store: https://play.google.com/store/apps/details?id=com.bookwithkhushipartner\n"
            "🍎 iOS App Store: https://apps.apple.com/app/id6774184822";
    final encoded = Uri.encodeComponent(msg);
    final smsUri = Uri.parse("sms:?body=$encoded");
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar("Error", "Could not open SMS app");
      }
    } catch (e) {
      Get.snackbar("Error", "Could not open SMS app");
    }
  }
}
