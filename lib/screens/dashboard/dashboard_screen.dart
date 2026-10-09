import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_controller.dart';
import '../../widgets/app_drawer.dart';
import '../../constants/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';
import '../profile/profile_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          FutureBuilder<int?>(
            future: Get.find<StorageService>().getVendorId(),
            builder: (context, idSnapshot) {
              final fallbackIcon = IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Get.toNamed(AppRoutes.notifications),
              );

              // Avoid crash if Firebase failed to initialize
              if (Firebase.apps.isEmpty) {
                return fallbackIcon;
              }

              if (!idSnapshot.hasData || idSnapshot.data == null) {
                return fallbackIcon;
              }
              final String vendorId = idSnapshot.data!.toString();
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userId', isEqualTo: vendorId)
                    .where('isRead', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  final int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return IconButton(
                    icon: Badge(
                      label: Text(unreadCount.toString()),
                      isLabelVisible: unreadCount > 0,
                      backgroundColor: AppColors.golden,
                      textColor: Colors.white,
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    onPressed: () => Get.toNamed(AppRoutes.notifications),
                    tooltip: 'Notifications',
                  );
                },
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Obx(() {
        // Removed full screen loading indicator so it loads instantly

        return RefreshIndicator(
          onRefresh: controller.fetchDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(context),
                const SizedBox(height: 16),
                _buildMembershipNotice(controller),
                const SizedBox(height: 16),
                _buildStatCards(controller),
                const SizedBox(height: 24),
                _buildIncomeChart(context, controller),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return GetBuilder<ProfileController>(
      init: ProfileController(),
      builder: (profileController) {
        return Obx(() {
          String userName = profileController.username.value;
          if (userName.isEmpty) {
             userName = 'User';
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $userName!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        });
      }
    );
  }

  Widget _buildMembershipNotice(DashboardController controller) {
    final membership = controller.membership;
    final bool hasActive = membership['has_active'] == true;

    // Hide banner if user has an active membership package or data is loading
    if (hasActive || controller.isLoading.value) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFFFDB94B), width: 5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFFDB94B), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your membership is expired. Please purchase a new package / extend the current package.',
              style: TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(DashboardController controller) {
    final stats = controller.stats;
    return Column(
      children: [
        _buildWebStyleCard(
          'My Balance', 
          '₹ ${stats['balance'] ?? 0}', 
          Icons.currency_rupee, 
          const Color(0xFF6B5DE3),
          () => Get.toNamed(AppRoutes.withdrawals)
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildWebStyleCard(
                'Transaction', 
                stats['transactions']?.toString() ?? '0', 
                Icons.swap_horiz, 
                const Color(0xFFFDB94B),
                () => Get.toNamed(AppRoutes.transactions)
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildWebStyleCard(
                'Space', 
                stats['spaces']?.toString() ?? '0', 
                Icons.info_outline, 
                const Color(0xFF38C94B),
                () => Get.toNamed(AppRoutes.spaces)
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildWebStyleCard(
                'Space Booking', 
                stats['bookings']?.toString() ?? '0', 
                Icons.receipt_long, 
                const Color(0xFFF7585C),
                () => Get.toNamed(AppRoutes.bookings)
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildWebStyleCard(
                'Subscription Log', 
                stats['subscription_logs']?.toString() ?? '0', 
                Icons.format_list_numbered, 
                const Color(0xFF4CB1F6),
                () => Get.toNamed(AppRoutes.subscriptionLog)
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWebStyleCard(String title, String count, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeChart(BuildContext context, DashboardController controller) {
    List<num> incomes = (controller.graphs['incomes'] as List?)
            ?.map((e) => num.tryParse(e.toString()) ?? 0)
            .toList() ?? [];
    List<num> bookings = (controller.graphs['bookings'] as List?)
            ?.map((e) => num.tryParse(e.toString()) ?? 0)
            .toList() ?? [];
    List<String> months = List<String>.from(controller.graphs['months'] ?? []);
    
    // Fallback if API returns empty graphs so UI doesn't look broken
    if (months.isEmpty) {
      months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    }
    if (incomes.isEmpty) {
      incomes = List.filled(months.length, 0);
    }
    if (bookings.isEmpty) {
      bookings = List.filled(months.length, 0);
    }

    return Column(
      children: [
        _buildLineChart(
          context: context, 
          title: 'Month Wise Total Incomes (${DateTime.now().year})', 
          data: incomes, 
          months: months, 
          lineColor: Colors.green,
          legendTitle: 'Month Wise Total Incomes'
        ),
        const SizedBox(height: 24),
        _buildLineChart(
          context: context, 
          title: 'Number of Space Bookings (${DateTime.now().year})', 
          data: bookings, 
          months: months, 
          lineColor: Colors.blue,
          legendTitle: 'Monthly Space Bookings'
        ),
      ],
    );
  }

  Widget _buildLineChart({
    required BuildContext context, 
    required String title, 
    required List<num> data, 
    required List<String> months, 
    required Color lineColor,
    required String legendTitle,
  }) {
    if (data.isEmpty) return const SizedBox();

    double maxVal = data.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxVal == 0) maxVal = 1; // Prevent divide by zero / flat axis

    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].toDouble()));
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2B334B), // Dark blue/grey matching web panel background
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: -maxVal, // Web panel has Y going from -1 to 1 even for 0 values. Let's make it symmetric.
                maxY: maxVal,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => const FlLine(color: Colors.white12, strokeWidth: 1),
                  getDrawingVerticalLine: (value) => const FlLine(color: Colors.white12, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < months.length) {
                          return Text(months[value.toInt()], style: const TextStyle(color: Colors.white70, fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toStringAsFixed(1), style: const TextStyle(color: Colors.white54, fontSize: 10));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.white12, width: 1),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    color: lineColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: lineColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 12,
                decoration: BoxDecoration(
                  border: Border.all(color: lineColor, width: 2),
                ),
              ),
              const SizedBox(width: 8),
              Text(legendTitle, style: TextStyle(color: lineColor, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}
