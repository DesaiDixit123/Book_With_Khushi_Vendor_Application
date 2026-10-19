import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'spaces_controller.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/app_drawer.dart';

class SpacesScreen extends StatelessWidget {
  const SpacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SpacesController());

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('My Spaces', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      floatingActionButton: Obx(() {
        if (controller.spacesList.isEmpty) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton.extended(
          onPressed: controller.checkMembershipAndAddSpace,
          backgroundColor: AppColors.navyBlue,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add New Space', style: TextStyle(fontWeight: FontWeight.bold)),
        );
      }),
      body: Column(
        children: [
          // Filter & Search Controls Header
          _buildFilterHeader(context, controller),

          // Main Body with RefreshIndicator
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: AppColors.golden));
              }

              if (controller.hasError.value) {
                return _buildErrorState(controller);
              }

              if (controller.spacesList.isEmpty) {
                return _buildEmptyState(context, controller);
              }

              return RefreshIndicator(
                onRefresh: controller.fetchSpaces,
                color: AppColors.navyBlue,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: controller.spacesList.length,
                  itemBuilder: (context, index) {
                    final space = controller.spacesList[index];
                    return _buildSpaceCard(context, space, controller);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // FILTER, SEARCH & SORT HEADER
  // -------------------------------------------------------------
  Widget _buildFilterHeader(BuildContext context, SpacesController controller) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Row 1: Search Field
          TextField(
            style: const TextStyle(fontSize: 14),
            onChanged: controller.updateSearch,
            decoration: InputDecoration(
              hintText: 'Search by title, city or location...',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppColors.navyBlue, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),

          // Row 2: Category Filter & Sort By Dropdowns
          Row(
            children: [
              // Category Filter Dropdown
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: Obx(() {
                      final List<String> catNames = ['All Categories'];
                      catNames.addAll(controller.categories.map((c) => c['name'].toString()));

                      String currentValue = controller.selectedCategory.value;
                      if (!catNames.contains(currentValue)) {
                        currentValue = 'All Categories';
                      }

                      return DropdownButton<String>(
                        isExpanded: true,
                        value: currentValue,
                        icon: const Icon(Icons.filter_list, color: AppColors.navyBlue, size: 18),
                        style: const TextStyle(color: Colors.black87, fontSize: 12),
                        items: catNames.map((v) =>
                          DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))
                        ).toList(),
                        onChanged: (val) => controller.updateCategory(val ?? 'All Categories'),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Sort By Dropdown
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: Obx(() {
                      final List<String> sortOptions = ['Latest', 'Oldest', 'Name A-Z', 'Name Z-A'];
                      return DropdownButton<String>(
                        isExpanded: true,
                        value: controller.selectedSort.value,
                        icon: const Icon(Icons.sort, color: AppColors.navyBlue, size: 18),
                        style: const TextStyle(color: Colors.black87, fontSize: 12),
                        items: sortOptions.map((opt) =>
                          DropdownMenuItem(value: opt, child: Text('Sort: $opt', overflow: TextOverflow.ellipsis))
                        ).toList(),
                        onChanged: (val) => controller.updateSort(val ?? 'Latest'),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SPACE CARD (REDESIGNED MATERIAL 3)
  // -------------------------------------------------------------
  Widget _buildSpaceCard(BuildContext context, Map<String, dynamic> space, SpacesController controller) {
    final title = space['title']?.toString() ?? 'Untitled Space';
    final category = space['category_name'] ?? space['category']?['name'] ?? 'General';
    final city = space['city'] ?? space['address'] ?? 'Location N/A';
    final price = space['space_rent'] ?? space['starting_price'] ?? space['price_per_day'] ?? '0';
    final thumb = space['thumbnail_image'];
    final isFeatured = space['is_featured'] == 1 || space['is_featured'] == '1';
    final updatedAt = space['updated_at'] ?? space['created_at'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: thumb != null && thumb.toString().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: thumb.toString(),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey.shade200),
                          errorWidget: (context, url, err) => const Icon(Icons.business, size: 50, color: Colors.grey),
                        )
                      : Container(color: Colors.grey.shade200, child: const Icon(Icons.business, size: 50, color: Colors.grey)),
                ),
              ),
              // Category Tag
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.navyBlue.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // Featured Badge
              if (isFeatured)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.golden,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('Featured', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Card Content
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        city.toString(),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Starting Price', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        Text(
                          '₹$price',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyBlue),
                        ),
                      ],
                    ),
                    if (updatedAt.toString().isNotEmpty)
                      Text(
                        'Updated: ${_formatDate(updatedAt.toString())}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                  ],
                ),
                const Divider(height: 20),

                // Card Action Buttons Row: Edit, Share, Delete
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => controller.editSpace(space),
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Edit', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: AppColors.navyBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareVendorSpace(context, space),
                        icon: const Icon(Icons.share_outlined, size: 14),
                        label: const Text('Share', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: Colors.teal.shade700,
                          side: BorderSide(color: Colors.teal.shade700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context, space['id'], controller),
                        icon: const Icon(Icons.delete_outline, size: 14),
                        label: const Text('Delete', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareVendorSpace(BuildContext context, Map<String, dynamic> space) {
    final spaceId = space['id']?.toString() ?? '';
    final title = space['title']?.toString() ?? 'Service';
    final rawBase = Get.find<ApiService>().baseUrl;
    final serverBase = rawBase.endsWith('/api')
        ? rawBase.substring(0, rawBase.length - 4)
        : rawBase;
    final smartUrl = '$serverBase/share/space/$spaceId';
    final msg = '🌟 *$title*\n\n'
        '👉 Tap this link to open & book directly in *Book with Khushi* App:\n'
        '$smartUrl\n\n'
        '📲 *Download Book with Khushi Customer App:*\n'
        '🤖 Android Play Store: https://play.google.com/store/apps/details?id=com.bookwithkhushi\n'
        '🍎 iOS App Store: https://apps.apple.com/app/id6773082164';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Share "$title"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final uri = Uri.parse(
                            'https://api.whatsapp.com/send?text=${Uri.encodeComponent(msg)}');
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('WhatsApp'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: msg));
                        Navigator.of(ctx).pop();
                        Get.snackbar(
                          'Copied!',
                          'Space share link copied to clipboard',
                          backgroundColor: AppColors.navyBlue,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy Link'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // EMPTY & ERROR STATES
  // -------------------------------------------------------------
  Widget _buildEmptyState(BuildContext context, SpacesController controller) {
    return RefreshIndicator(
      onRefresh: controller.fetchSpaces,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.maps_home_work_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No Spaces Found',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap the "+ Add New Space" button to create your first space listing.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: controller.checkMembershipAndAddSpace,
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Space'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(SpacesController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 70, color: AppColors.error),
          const SizedBox(height: 16),
          const Text('Failed to load spaces', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: controller.fetchSpaces,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, dynamic spaceId, SpacesController controller) {
    final id = int.tryParse(spaceId.toString());
    if (id == null) return;

    Get.defaultDialog(
      title: 'Delete Space',
      middleText: 'Are you sure you want to delete this space? This action cannot be undone.',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.error,
      onConfirm: () {
        Get.back();
        controller.deleteSpace(id);
      },
    );
  }

  void _showPromoteModal(BuildContext context, Map<String, dynamic> space, SpacesController controller) {
    controller.fetchFeaturePrerequisites();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Feature & Promote "${space['title']}"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            const Text('Promote your space on the homepage header to get 5x more bookings.', style: TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  controller.checkMembershipAndAddSpace();
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyBlue, foregroundColor: Colors.white),
                child: const Text('Manage Featured Promotion'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return rawDate;
    }
  }
}
