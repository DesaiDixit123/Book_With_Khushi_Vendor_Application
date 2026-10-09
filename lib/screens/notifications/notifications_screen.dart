import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../services/storage_service.dart';
import '../profile/profile_controller.dart';
import '../bookings/bookings_controller.dart';

class VendorNotificationData {
  final String id;
  final String title;
  final String message;
  final dynamic createdAt;
  final bool isRead;
  final String type;

  VendorNotificationData({
    required this.id,
    required this.title,
    required this.message,
    this.createdAt,
    this.isRead = true,
    this.type = 'booking',
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ProfileController _profileController = Get.put(ProfileController());
  String? _vendorId;
  bool _isLoadingId = true;

  @override
  void initState() {
    super.initState();
    _loadVendorId();
  }

  Future<void> _loadVendorId() async {
    int? id = _profileController.vendorId.value;
    
    if (id == null) {
      id = await Get.find<StorageService>().getVendorId();
    }

    if (id == null) {
      await _profileController.fetchProfile();
      id = _profileController.vendorId.value;
    }

    if (mounted) {
      setState(() {
        _vendorId = id?.toString();
        _isLoadingId = false;
      });
    }
  }

  Future<void> _markAsRead(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _deleteNotification(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    if (_vendorId == null) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      final docs = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: _vendorId)
          .where('isRead', isEqualTo: false)
          .get();
      
      for (var doc in docs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      
      Get.snackbar(
        'Success',
        'All notifications marked as read',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.navyBlue.withOpacity(0.9),
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final BookingsController bookingsController = Get.isRegistered<BookingsController>()
        ? Get.find<BookingsController>()
        : Get.put(BookingsController());

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_vendorId != null)
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.white),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            )
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoadingId
          ? const Center(child: CircularProgressIndicator(color: AppColors.golden))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: _vendorId)
                  .snapshots(),
              builder: (context, snapshot) {
                final List<VendorNotificationData> mergedList = [];

                // 1. Map Firestore notifications if available
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    mergedList.add(VendorNotificationData(
                      id: doc.id,
                      title: data['title'] ?? 'Notification',
                      message: data['message'] ?? '',
                      createdAt: data['createdAt'],
                      isRead: data['isRead'] == true,
                      type: data['type'] ?? 'booking',
                    ));
                  }
                }

                // 2. Map Vendor Bookings as Notification entries
                if (bookingsController.bookingsList.isNotEmpty) {
                  for (var b in bookingsController.bookingsList) {
                    final Map<String, dynamic> item = b is Map<String, dynamic> ? b : Map<String, dynamic>.from(b);
                    final bNo = item['booking_number'] ?? item['id']?.toString() ?? 'N/A';
                    final spaceName = item['space_name'] ?? item['space']?['title'] ?? item['space_title'] ?? 'Space';
                    final status = (item['booking_status'] ?? item['status'] ?? 'New').toString().toUpperCase();
                    final date = item['booking_date'] ?? item['created_at'] ?? '';
                    final total = item['grand_total'] ?? item['total'] ?? '0';

                    // Avoid duplicate if already present in firestore
                    final exists = mergedList.any((n) => n.message.contains(bNo.toString()));
                    if (!exists) {
                      mergedList.add(VendorNotificationData(
                        id: "booking_$bNo",
                        title: "New Space Booking #$bNo $status 🚀",
                        message: "Booking received for '$spaceName'. Customer: ${item['customer_name'] ?? item['name'] ?? 'Customer'}. Amount: ₹$total",
                        createdAt: date,
                        isRead: true,
                        type: 'booking',
                      ));
                    }
                  }
                }

                if (mergedList.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      await bookingsController.fetchBookings();
                      setState(() {});
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off_outlined, size: 80, color: AppColors.textGrey),
                              SizedBox(height: 16),
                              Text(
                                'No notifications yet',
                                style: TextStyle(color: AppColors.textLight, fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await bookingsController.fetchBookings();
                    setState(() {});
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: mergedList.length,
                    itemBuilder: (context, index) {
                      final item = mergedList[index];
                      return _buildNotificationItem(item);
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildNotificationItem(VendorNotificationData item) {
    // Parse createdAt dynamic type
    DateTime? date;
    if (item.createdAt is Timestamp) {
      date = (item.createdAt as Timestamp).toDate();
    } else if (item.createdAt is int) {
      date = DateTime.fromMillisecondsSinceEpoch(item.createdAt);
    } else if (item.createdAt is String && (item.createdAt as String).isNotEmpty) {
      date = DateTime.tryParse(item.createdAt);
    }

    final dateStr = date != null
        ? DateFormat('MMM dd, yyyy - hh:mm a').format(date)
        : (item.createdAt?.toString() ?? '');

    IconData iconData;
    Color iconColor;

    switch (item.type) {
      case 'booking':
        iconData = Icons.check_circle_outline;
        iconColor = Colors.green;
        break;
      case 'referral':
        iconData = Icons.person_add_alt_1_outlined;
        iconColor = Colors.teal;
        break;
      case 'offer':
      case 'bonus':
        iconData = Icons.card_giftcard_outlined;
        iconColor = AppColors.golden;
        break;
      case 'payment':
      case 'redeem':
        iconData = Icons.account_balance_wallet_outlined;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.notifications_none_outlined;
        iconColor = AppColors.navyBlue;
    }

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        if (!item.id.startsWith('booking_')) {
          _deleteNotification(item.id);
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () {
          if (!item.isRead && !item.id.startsWith('booking_')) {
            _markAsRead(item.id);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: !item.isRead ? AppColors.beigeCream.withOpacity(0.3) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: !item.isRead ? AppColors.navyBlue.withOpacity(0.15) : Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: !item.isRead ? FontWeight.bold : FontWeight.w600,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!item.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.golden,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
