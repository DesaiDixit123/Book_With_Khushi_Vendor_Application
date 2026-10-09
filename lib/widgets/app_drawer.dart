import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../screens/auth/auth_controller.dart';
import '../screens/profile/profile_controller.dart';
import '../screens/bookings/requests_controller.dart';
import '../screens/bookings/bookings_controller.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Struct for flat filtered search items
  late final List<Map<String, dynamic>> _flatSearchItems = [
    {
      'title': 'Dashboard',
      'icon': Icons.dashboard,
      'onTap': () {
        Get.back();
        Get.offAllNamed(AppRoutes.dashboard);
      }
    },
    {
      'title': 'Notifications',
      'icon': Icons.notifications_outlined,
      'onTap': () {
        Get.back();
        Get.toNamed(AppRoutes.notifications);
      }
    },
    {
      'title': 'My Spaces',
      'icon': Icons.holiday_village,
      'onTap': () {
        Get.back();
        Get.toNamed(AppRoutes.spaces);
      }
    },
    {
      'title': 'Holidays',
      'icon': Icons.beach_access,
      'onTap': () {
        Get.back();
        Get.toNamed(AppRoutes.holidays);
      }
    },
    // {
    //   'title': 'Forms',
    //   'icon': Icons.format_list_bulleted,
    //   'onTap': () {
    //     Get.back();
    //     Get.toNamed(AppRoutes.forms);
    //   }
    // },
    {
      'title': 'Coupons',
      'icon': Icons.local_offer,
      'onTap': () {
        Get.back();
        Get.toNamed(AppRoutes.coupons);
      }
    },
    {
      'title': 'Booking Management',
      'icon': Icons.book_online,
      'onTap': () {
        Get.back();
        Get.toNamed(AppRoutes.bookings);
      }
    },
    // {
    //   'title': 'Quote Requests',
    //   'icon': Icons.request_quote,
    //   'onTap': () {
    //     Get.back();
    //     Get.toNamed(AppRoutes.quoteRequests);
    //   }
    // },
    // {
    //   'title': 'Tour Requests',
    //   'icon': Icons.tour,
    //   'onTap': () {
    //     Get.back();
    //     Get.toNamed(AppRoutes.tourRequests);
    //   }
    // },
    {
      'title': 'Check Limit',
      'icon': Icons.analytics_outlined,
      'onTap': () {
        Get.back();
        Get.toNamed(AppRoutes.checkLimit);
      }
    },
    {
      'title': 'Buy Plan',
      'icon': Icons.card_membership,
      'onTap': () {
        Get.back();
        Get.toNamed(AppRoutes.subscription);
      }
    },
    {
      'title': 'Subscription Log',
      'icon': Icons.history,
      'onTap': () {
        Get.back();
        Get.toNamed(AppRoutes.subscriptionLog);
      }
    },
    {
      'title': 'Withdrawals',
      'icon': Icons.account_balance_wallet,
      'onTap': () {
        Get.back();
        Get.toNamed(AppRoutes.withdrawals);
      }
    },
    {
      'title': 'Make a Request',
      'icon': Icons.add_circle_outline,
      'onTap': () {
        Get.back();
        Get.toNamed(AppRoutes.makeRequest);
      }
    },
    {
      'title': 'Transactions',
      'icon': Icons.receipt,
      'onTap': () {
        Get.back();
        Get.toNamed(AppRoutes.transactions);
      }
    },
    {
      'title': 'Refer & Earn',
      'icon': Icons.share_location,
      'onTap': () {
        Get.back();
        Get.toNamed(AppRoutes.referral);
      }
    },
    {
      'title': 'Reward Wallet',
      'icon': Icons.account_balance_wallet_rounded,
      'onTap': () {
        Get.back();
        Get.toNamed(AppRoutes.wallet);
      }
    },
    {
      'title': 'Edit Profile',
      'icon': Icons.person,
      'onTap': () {
        Get.back();
        Get.toNamed(AppRoutes.profile);
      }
    },
    // {
    //   'title': 'Recipient Mail',
    //   'icon': Icons.mail,
    //   'onTap': () {
    //     Get.back();
    //     Get.toNamed(AppRoutes.recipientMail);
    //   }
    // },
    {
      'title': 'Change Password',
      'icon': Icons.lock,
      'onTap': () {
        Get.back();
        Get.toNamed(AppRoutes.changePassword);
      }
    },
    {
      'title': 'Logout',
      'icon': Icons.logout,
      'onTap': () {
        final authController = Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController());
        authController.logout();
      },
      'color': AppColors.error
    },
  ];

  void _navigateToQuoteRequests(String status) {
    Get.back();
    if (Get.currentRoute == AppRoutes.quoteRequests) {
      if (Get.isRegistered<RequestsController>()) {
        Get.find<RequestsController>().quoteFilter.value = status;
      }
    } else {
      Get.toNamed(AppRoutes.quoteRequests, arguments: status);
    }
  }

  void _navigateToTourRequests(String status) {
    Get.back();
    if (Get.currentRoute == AppRoutes.tourRequests) {
      if (Get.isRegistered<RequestsController>()) {
        Get.find<RequestsController>().tourFilter.value = status;
      }
    } else {
      Get.toNamed(AppRoutes.tourRequests, arguments: status);
    }
  }

  void _navigateToBookings(String status) {
    Get.back();
    if (Get.currentRoute == AppRoutes.bookings) {
      if (Get.isRegistered<BookingsController>()) {
        Get.find<BookingsController>().bookingFilter.value = status;
      }
    } else {
      Get.toNamed(AppRoutes.bookings, arguments: status);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If query is not empty, filter items
    final filteredItems = _searchQuery.isEmpty
        ? <Map<String, dynamic>>[]
        : _flatSearchItems
            .where((item) => item['title']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.only(bottom: bottomPadding),
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.navyBlue,
            ),
            child: Obx(() {
              final profileController = Get.find<ProfileController>();
              final vendorName = profileController.vendorName.value;
              final isLoading = profileController.isLoading.value;
              final displayName = vendorName.isNotEmpty
                  ? vendorName
                  : (isLoading ? 'Loading...' : 'Partner');

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 30,
                        child: Icon(Icons.person, size: 40, color: AppColors.navyBlue),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Partner',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }),
          ),
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search Menu Here...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                filled: true,
                fillColor: AppColors.beigeCream.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.maroon, width: 1.5),
                ),
              ),
            ),
          ),
          const Divider(),

          // If searching, show search results
          if (_searchQuery.isNotEmpty)
            if (filteredItems.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No menu item found.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...filteredItems.map((item) => _buildDrawerItem(
                    item['icon'],
                    item['title'],
                    item['onTap'],
                    color: item['color'] ?? AppColors.textLight,
                  ))
          else ...[
            // Default Menu structure
            _buildDrawerItem(Icons.dashboard, 'Dashboard', () {
              Get.back();
              Get.offAllNamed(AppRoutes.dashboard);
            }),

            _buildDrawerItem(Icons.notifications_outlined, 'Notifications', () {
              Get.back();
              Get.toNamed(AppRoutes.notifications);
            }),

            _buildExpansionTile(Icons.info_outline, 'Space Management', [
              _buildSubItem('Holidays', () {
                Get.back();
                Get.toNamed(AppRoutes.holidays);
              }),
              // _buildSubItem('Forms', () {
              //   Get.back();
              //   Get.toNamed(AppRoutes.forms);
              // }),
              _buildSubItem('Coupons', () {
                Get.back();
                Get.toNamed(AppRoutes.coupons);
              }),
              _buildSubItem('Spaces', () {
                Get.back();
                Get.toNamed(AppRoutes.spaces);
              }),
            ]),

            _buildExpansionTile(Icons.calendar_today, 'Bookings & Requests', [
              // _buildSubExpansionTileWithChildren(
              //   'Quote Requests',
              //   [
              //     _buildDeepSubItem('All Requests', () => _navigateToQuoteRequests('all')),
              //     _buildDeepSubItem('Pending Requests', () => _navigateToQuoteRequests('pending')),
              //     _buildDeepSubItem('Responded Requests', () => _navigateToQuoteRequests('responded')),
              //     _buildDeepSubItem('In Progress Requests', () => _navigateToQuoteRequests('in_progress')),
              //     _buildDeepSubItem('Closed Requests', () => _navigateToQuoteRequests('closed')),
              //     _buildDeepSubItem('Cancelled Requests', () => _navigateToQuoteRequests('cancelled')),
              //   ],
              // ),
              // _buildSubExpansionTileWithChildren(
              //   'Tour Requests',
              //   [
              //     _buildDeepSubItem('All Requests', () => _navigateToTourRequests('all')),
              //     _buildDeepSubItem('Pending Requests', () => _navigateToTourRequests('pending')),
              //     _buildDeepSubItem('Confirmed Requests', () => _navigateToTourRequests('confirmed')),
              //     _buildDeepSubItem('Closed Requests', () => _navigateToTourRequests('closed')),
              //     _buildDeepSubItem('Cancelled Requests', () => _navigateToTourRequests('cancelled')),
              //   ],
              // ),
              _buildSubExpansionTileWithChildren(
                'Booking Management',
                [
                  _buildDeepSubItem('All Bookings', () => _navigateToBookings('all')),
                  _buildDeepSubItem('Pending Bookings', () => _navigateToBookings('pending')),
                  _buildDeepSubItem('Approved Bookings', () => _navigateToBookings('approved')),
                  _buildDeepSubItem('Rejected Bookings', () => _navigateToBookings('rejected')),
                  _buildDeepSubItem('Report', () => _navigateToBookings('report')),
                ],
              ),
            ]),

            _buildDrawerItem(Icons.analytics_outlined, 'Check Limit', () {
              Get.back();
              Get.toNamed(AppRoutes.checkLimit);
            }),

            _buildExpansionTile(Icons.receipt_long, 'Subscription', [
              _buildSubItem('Buy Plan', () {
                Get.back();
                Get.toNamed(AppRoutes.subscription);
              }),
              _buildSubItem('Subscription Log', () {
                Get.back();
                Get.toNamed(AppRoutes.subscriptionLog);
              }),
            ]),

            _buildExpansionTile(Icons.account_balance_wallet_outlined, 'Withdrawals', [
              _buildSubItem('Withdrawal Requests', () {
                Get.back();
                Get.toNamed(AppRoutes.withdrawals);
              }),
              _buildSubItem('Make a Request', () {
                Get.back();
                Get.toNamed(AppRoutes.makeRequest);
              }),
            ]),

            _buildDrawerItem(Icons.receipt, 'Transactions', () {
              Get.back();
              Get.toNamed(AppRoutes.transactions);
            }),

            _buildExpansionTile(Icons.celebration, 'Referral System', [
              _buildSubItem('Referral Dashboard', () {
                Get.back();
                Get.toNamed(AppRoutes.referral);
              }),
              _buildSubItem('Referral History', () {
                Get.back();
                Get.toNamed(AppRoutes.referralHistory);
              }),
              _buildSubItem('Reward Wallet', () {
                Get.back();
                Get.toNamed(AppRoutes.wallet);
              }),
              _buildSubItem('Bank Details', () {
                Get.back();
                Get.toNamed(AppRoutes.bankDetails);
              }),
            ]),

            _buildDrawerItem(Icons.person, 'Edit Profile', () {
              Get.back();
              Get.toNamed(AppRoutes.profile);
            }),

            // _buildDrawerItem(Icons.mail, 'Recipient Mail', () {
            //   Get.back();
            //   Get.toNamed(AppRoutes.recipientMail);
            // }),

            _buildDrawerItem(Icons.lock, 'Change Password', () {
              Get.back();
              Get.toNamed(AppRoutes.changePassword);
            }),

            const Divider(),
            _buildDrawerItem(Icons.security, 'Privacy Policy', () {
              Get.back();
              Get.toNamed(AppRoutes.privacy);
            }),

            _buildDrawerItem(
              Icons.logout,
              'Logout',
              () {
                final authController = Get.isRegistered<AuthController>()
                    ? Get.find<AuthController>()
                    : Get.put(AuthController());
                authController.logout();
              },
              color: AppColors.error,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color color = AppColors.textLight}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  Widget _buildExpansionTile(IconData icon, String title, List<Widget> children) {
    return ExpansionTile(
      leading: Icon(icon, color: AppColors.textLight),
      title: Text(title, style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w500)),
      iconColor: AppColors.textLight,
      collapsedIconColor: AppColors.textLight,
      childrenPadding: EdgeInsets.zero,
      children: children,
    );
  }

  Widget _buildSubItem(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 32.0),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.textLight,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sub-item expandable with actual children (e.g. Quote Requests → All, Pending, etc.)
  Widget _buildSubExpansionTileWithChildren(String title, List<Widget> children) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 32.0),
        minTileHeight: 48,
        leading: Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(top: 1),
          decoration: const BoxDecoration(
            color: AppColors.textLight,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        iconColor: AppColors.textLight,
        collapsedIconColor: AppColors.textLight,
        childrenPadding: EdgeInsets.zero,
        children: children,
      ),
    );
  }

  /// Sub-item that looks like a bullet + title + dropdown arrow (nested expandable style)
  Widget _buildSubExpansionTile(String title, VoidCallback onTap) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 32.0),
        minTileHeight: 48,
        leading: Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(top: 1),
          decoration: const BoxDecoration(
            color: AppColors.textLight,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        iconColor: AppColors.textLight,
        collapsedIconColor: AppColors.textLight,
        childrenPadding: EdgeInsets.zero,
        onExpansionChanged: (_) => onTap(),
        children: const [],
      ),
    );
  }

  /// Deepest-level bullet item (indented further for 3rd level)
  Widget _buildDeepSubItem(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11.0, horizontal: 52.0),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.textLight.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textLight.withOpacity(0.85),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
