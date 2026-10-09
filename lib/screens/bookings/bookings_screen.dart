import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'bookings_controller.dart';
import '../../constants/app_colors.dart';
import '../../widgets/app_drawer.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  late BookingsController controller;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    controller = Get.put(BookingsController());
    controller.bookingFilter.value = Get.arguments as String? ?? 'all';
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase().trim()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _appBarTitle(String? status) {
    switch (status) {
      case 'pending':   return 'Pending Bookings';
      case 'approved':  return 'Approved Bookings';
      case 'rejected':  return 'Rejected Bookings';
      case 'report':    return 'Bookings Report';
      default:          return 'All Bookings';
    }
  }

  List<dynamic> _filterList(List<dynamic> list, String? status) {
    List<dynamic> filtered = list;
    if (status != null && status != 'all' && status != 'report') {
      filtered = list.where((b) {
        final s = (b['booking_status'] ?? '').toString().toLowerCase();
        if (status == 'approved') return s == 'accepted' || s == 'completed';
        if (status == 'rejected') return s == 'rejected';
        if (status == 'pending')  return s == 'pending';
        return true;
      }).toList();
    }

    if (_query.isNotEmpty) {
      filtered = filtered.where((b) {
        final spaceTitle = (b['space_title'] ?? '').toString().toLowerCase();
        final custName = (b['customer_name'] ?? '').toString().toLowerCase();
        final custPhone = (b['customer_phone'] ?? '').toString().toLowerCase();
        final bookingNum = (b['booking_number'] ?? b['id'] ?? '').toString().toLowerCase();
        return spaceTitle.contains(_query) ||
            custName.contains(_query) ||
            custPhone.contains(_query) ||
            bookingNum.contains(_query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final String statusFilter = controller.bookingFilter.value;

      return Scaffold(
        appBar: AppBar(
          title: Text(_appBarTitle(statusFilter)),
        ),
        drawer: const AppDrawer(),
        body: Column(
          children: [
            if (statusFilter != 'report') ...[
              // ── Search Bar ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by Space, Name, Phone, ID...',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    isDense: true,
                  ),
                ),
              ),
            ],
            Expanded(
              child: controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : Builder(
                      builder: (context) {
                        // Report view — placeholder for now
                        if (statusFilter == 'report') {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bar_chart, size: 64, color: AppColors.navyBlue.withOpacity(0.4)),
                                const SizedBox(height: 16),
                                const Text('Bookings Report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
                                const SizedBox(height: 8),
                                const Text('Coming Soon', style: TextStyle(fontSize: 15, color: Colors.grey)),
                              ],
                            ),
                          );
                        }

                        final filtered = _filterList(controller.bookingsList, statusFilter);

                        if (filtered.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.event_busy, size: 80, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  _query.isNotEmpty ? 'No search results found.' : 'No bookings found.',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                if (_query.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'No match found for "$_query"',
                                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: controller.fetchBookings,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final booking = filtered[index];
                              return _buildBookingCard(context, booking, controller);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBookingCard(BuildContext context, Map<String, dynamic> booking, BookingsController controller) {
    Color statusColor;
    switch (booking['booking_status']) {
      case 'accepted':
      case 'completed':
        statusColor = AppColors.success;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.golden; // pending
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${booking['booking_number'] ?? booking['id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    (booking['booking_status'] ?? 'pending').toString().toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.holiday_village, size: 18, color: AppColors.navyBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking['space_title'],
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(booking['customer_name'] ?? 'Unknown Customer'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(booking['customer_phone'] ?? 'No Phone'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Date/Time', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(booking['created_at'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Amount', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(
                      '${booking['currency_text']}${booking['grand_total']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.maroon, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final bool isRazorpay = (booking['payment_method'] ?? '').toString().toLowerCase() == 'razorpay';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isRazorpay ? Colors.green.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isRazorpay ? Colors.green.shade300 : Colors.amber.shade400),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(isRazorpay ? Icons.check_circle : Icons.money, size: 14, color: isRazorpay ? Colors.green.shade800 : Colors.brown.shade800),
                          const SizedBox(width: 6),
                          Text(
                            isRazorpay ? "PAID ONLINE (RAZORPAY)" : "COLLECT CASH AT VENUE",
                            style: TextStyle(
                              color: isRazorpay ? Colors.green.shade900 : Colors.brown.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${booking['currency_text']}${booking['grand_total']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isRazorpay ? Colors.green.shade900 : Colors.brown.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (booking['booking_status'] == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                      onPressed: () => controller.updateBookingStatus(booking['id'], 'rejected'),
                      child: const Text('REJECT'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      onPressed: () => controller.updateBookingStatus(booking['id'], 'accepted'),
                      child: const Text('ACCEPT', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showBookingDetails(context, booking),
                  icon: const Icon(Icons.visibility, size: 16, color: Colors.white),
                  label: const Text('VIEW', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: const Size(80, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _confirmDeleteBooking(context, booking['id']),
                  icon: const Icon(Icons.delete, size: 16, color: Colors.white),
                  label: const Text('DELETE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: const Size(80, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showBookingDetails(BuildContext context, Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) {
        final currency = booking['currency_text'] ?? '₹';
        final bookingType = booking['booking_type']; // 1 = timeslot, 2 = hourly, 3 = daily
        
        String dateRange = booking['created_at'] ?? '';
        if (bookingType == 3) {
          dateRange = '${booking['start_date'] ?? ''} - ${booking['end_date'] ?? ''}';
        } else if (bookingType == 1 || bookingType == 2) {
          dateRange = '${booking['booking_date'] ?? ''} (${booking['start_time'] ?? ''} - ${booking['end_time'] ?? ''})';
        }

        return AlertDialog(
          title: const Text('Booking Details', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Booking No.', '#${booking['booking_number'] ?? booking['id']}'),
                  _buildDetailRow('Space Title', booking['space_title'] ?? 'Unknown Space'),
                  _buildDetailRow('Customer Name', booking['customer_name'] ?? 'No Name'),
                  _buildDetailRow('Email Address', booking['customer_email'] ?? 'No Email'),
                  _buildDetailRow('Phone Number', booking['customer_phone'] ?? 'No Phone'),
                  _buildDetailRow('Date/Time', dateRange),
                  if (booking['number_of_guest'] != null)
                    _buildDetailRow('Number of Guests', booking['number_of_guest'].toString()),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(),
                  ),
                  const Text('Payment Details:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.maroon, fontSize: 14)),
                  const SizedBox(height: 6),
                  _buildDetailRow('Sub Total', '$currency ${booking['sub_total'] ?? 0}'),
                  if (booking['discount'] != null && num.tryParse(booking['discount'].toString()) != 0)
                    _buildDetailRow('Discount', '$currency ${booking['discount']}'),
                  if (booking['tax'] != null && num.tryParse(booking['tax'].toString()) != 0)
                    _buildDetailRow('Tax (Admin)', '$currency ${booking['tax']}'),
                  _buildDetailRow('Grand Total', '$currency ${booking['grand_total'] ?? 0}'),
                  _buildDetailRow(
                    'Payment Mode',
                    (booking['payment_method'] ?? '').toString().toLowerCase() == 'razorpay'
                        ? 'Razorpay (100% Online Paid)'
                        : 'Cash Payment (100% at Venue)',
                  ),
                  _buildDetailRow(
                    'Payment Status',
                    (booking['payment_method'] ?? '').toString().toLowerCase() == 'razorpay'
                        ? 'COMPLETED (PAID ONLINE)'
                        : 'PENDING (COLLECT CASH)',
                  ),
                  _buildDetailRow(
                    (booking['payment_method'] ?? '').toString().toLowerCase() == 'razorpay'
                        ? 'Paid Online'
                        : 'Cash to Collect',
                    '$currency ${booking['grand_total'] ?? 0}',
                  ),
                  _buildDetailRow('Booking Status', (booking['booking_status'] ?? 'pending').toString().toUpperCase()),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBooking(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Booking'),
          content: const Text('Are you sure you want to delete this booking record?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                controller.deleteBooking(id);
              },
              child: const Text('DELETE', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
