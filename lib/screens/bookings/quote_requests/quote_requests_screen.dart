import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:get/get.dart';
import '../requests_controller.dart';
import '../../../widgets/app_drawer.dart';
import '../../../constants/app_colors.dart';

class QuoteRequestsScreen extends StatefulWidget {
  const QuoteRequestsScreen({super.key});

  @override
  State<QuoteRequestsScreen> createState() => _QuoteRequestsScreenState();
}

class _QuoteRequestsScreenState extends State<QuoteRequestsScreen> {
  late RequestsController controller;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    controller = Get.put(RequestsController());
    controller.quoteFilter.value = Get.arguments as String? ?? 'all';
    controller.fetchQuotes();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase().trim()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'all':         return 'All Requests';
      case 'pending':     return 'Pending Requests';
      case 'responded':   return 'Responded Requests';
      case 'in_progress': return 'In Progress Requests';
      case 'closed':      return 'Closed Requests';
      case 'cancelled':   return 'Cancelled Requests';
      default:            return 'All Requests';
    }
  }

  List<dynamic> _filterList(List<dynamic> list, String? status) {
    List<dynamic> filtered = list;

    if (status != null && status != 'all') {
      filtered = list.where((q) {
        final s = (q['status'] ?? '').toString().toLowerCase();
        return s == status.toLowerCase();
      }).toList();
    }

    if (_query.isNotEmpty) {
      filtered = filtered.where((q) {
        final spaceTitle = (q['space_title'] ?? '').toString().toLowerCase();
        final custName = (q['customer_name'] ?? '').toString().toLowerCase();
        final custEmail = (q['customer_email'] ?? '').toString().toLowerCase();
        final bookingNum = (q['booking_number'] ?? q['id'] ?? '').toString().toLowerCase();
        return spaceTitle.contains(_query) ||
            custName.contains(_query) ||
            custEmail.contains(_query) ||
            bookingNum.contains(_query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final String statusFilter = controller.quoteFilter.value;
      final String title = _formatStatus(statusFilter);

      return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        drawer: const AppDrawer(),
        body: Column(
          children: [
            // ── Search Bar ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by Space, Customer, Email, ID...',
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
            // ── List ──────────────────────────────────────────────
            Expanded(
              child: controller.isLoadingQuotes.value
                  ? const Center(child: CircularProgressIndicator())
                  : Builder(
                      builder: (context) {
                        final filtered = _filterList(controller.quotesList, statusFilter);

                        if (filtered.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.request_quote_outlined, size: 72, color: AppColors.navyBlue.withOpacity(0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  _query.isNotEmpty ? 'NO RESULTS FOUND' : 'NO REQUESTS FOUND',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                                      color: Colors.grey, letterSpacing: 1),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _query.isNotEmpty
                                      ? 'No quote requests match "$_query"'
                                      : 'No quote requests in this category yet.',
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: controller.fetchQuotes,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final quote = filtered[index];
                              return _buildQuoteCard(context, quote);
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

  Widget _buildQuoteCard(BuildContext context, Map<String, dynamic> quote) {
    final status = (quote['status'] ?? 'pending').toString().toLowerCase();
    Color statusColor;
    switch (status) {
      case 'closed':
        statusColor = Colors.grey;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        break;
      case 'responded':
        statusColor = AppColors.success;
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = AppColors.golden; // pending
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${quote['booking_number'] ?? quote['id']}',
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
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.holiday_village, size: 16, color: AppColors.navyBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    quote['space_title'] ?? 'Unknown Space',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navyBlue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(quote['customer_name'] ?? 'No Name', style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.email, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(quote['customer_email'] ?? 'No Email', style: const TextStyle(fontSize: 13)),
              ],
            ),
            if (quote['created_at'].toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(quote['created_at'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
            // Action status dropdown
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Change Status:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: status,
                      style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
                      dropdownColor: Colors.white,
                      items: const [
                        DropdownMenuItem(value: 'pending', child: Text('PENDING')),
                        DropdownMenuItem(value: 'in_progress', child: Text('IN PROGRESS')),
                        DropdownMenuItem(value: 'responded', child: Text('RESPONDED')),
                        DropdownMenuItem(value: 'closed', child: Text('CLOSED')),
                        DropdownMenuItem(value: 'cancelled', child: Text('CANCELLED')),
                      ],
                      onChanged: (val) {
                        if (val != null && val != status) {
                          controller.updateQuoteStatus(quote['id'], val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showRequestDetails(context, quote, 'Quote Request Details'),
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
                  onPressed: () => _confirmDeleteQuote(context, quote['id']),
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
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestDetails(BuildContext context, Map<String, dynamic> request, String title) {
    Map<String, dynamic> info = {};
    if (request['information'] != null) {
      try {
        info = jsonDecode(request['information'].toString());
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Request ID', '#${request['booking_number'] ?? request['id']}'),
                  _buildDetailRow('Space Title', request['space_title'] ?? 'Unknown Space'),
                  _buildDetailRow('Customer Name', request['customer_name'] ?? 'No Name'),
                  _buildDetailRow('Email Address', request['customer_email'] ?? 'No Email'),
                  _buildDetailRow('Status', (request['status'] ?? 'pending').toString().toUpperCase()),
                  _buildDetailRow('Created At', request['created_at'] ?? ''),
                  if (info.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(thickness: 1.2),
                    ),
                    const Text('Additional Information:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.maroon)),
                    const SizedBox(height: 8),
                    ...info.entries.map((entry) {
                      final key = entry.key;
                      final data = entry.value;
                      if (data is Map) {
                        final type = data['type'];
                        final val = data['value'];
                        final originalName = data['originalName'];
                        
                        String displayVal = '-';
                        if (val != null) {
                          if (val is List) {
                            displayVal = val.join(', ');
                          } else {
                            displayVal = val.toString();
                          }
                        }
                        
                        final formattedLabel = key.replaceAll('_', ' ').split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join(' ');
                        
                        if (type == 8) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(formattedLabel, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.attach_file, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(originalName ?? displayVal, style: const TextStyle(fontSize: 14))),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return _buildDetailRow(formattedLabel, displayVal);
                      }
                      return const SizedBox.shrink();
                    }).toList(),
                  ],
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }

  void _confirmDeleteQuote(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Request'),
          content: const Text('Are you sure you want to delete this quote request?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                controller.deleteQuote(id);
              },
              child: const Text('DELETE', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
