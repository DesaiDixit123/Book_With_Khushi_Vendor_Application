import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import '../../services/api_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../constants/app_colors.dart';
import 'spaces_controller.dart';
import 'add_space_screen.dart';

class DayTiming {
  String openTime;
  String closeTime;
  bool isWeeklyOff;

  DayTiming({
    this.openTime = '09:00 AM',
    this.closeTime = '09:00 PM',
    this.isWeeklyOff = false,
  });

  Map<String, dynamic> toJson() => {
        'open_time': openTime,
        'close_time': closeTime,
        'is_weekly_off': isWeeklyOff,
      };
}

class AddSpaceController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final currentStep = 0.obs; // 0 to 6 (7 Steps)
  final isLoading = false.obs;
  final isPrerequisitesLoading = true.obs;

  // Prerequisites
  final categories = <Map<String, dynamic>>[].obs;
  final amenities = <Map<String, dynamic>>[].obs;

  // -------------------------------------------------------------
  // STEP 1: BASIC INFORMATION CONTROLLERS
  // -------------------------------------------------------------
  final titleController = TextEditingController();
  final businessNameController = TextEditingController();
  final ownerNameController = TextEditingController();
  final mobileController = TextEditingController();
  final whatsappController = TextEditingController();
  final emailController = TextEditingController();
  final cityController = TextEditingController();
  final areaController = TextEditingController();
  final addressController = TextEditingController();
  final googleMapController = TextEditingController();
  final experienceController = TextEditingController();
  final priceController = TextEditingController(); // Starting Price *
  final descriptionController = TextEditingController(); // About Business

  final titleText = ''.obs;

  // Selected Category & Subcategory/Type
  final selectedCategoryId = Rxn<int>();
  final selectedSubcategoryId = Rxn<int>();
  final selectedSpaceType = 1.obs; // 1 = Fixed Timeslot, 2 = Hourly, 3 = Multi Day
  final selectedAmenities = <int>[].obs;

  // -------------------------------------------------------------
  // STEP 2: DYNAMIC CATEGORY DETAILS
  // -------------------------------------------------------------
  final customFieldControllers = <String, TextEditingController>{}.obs;
  final sizeController = TextEditingController();
  final maxGuestController = TextEditingController();
  final minGuestController = TextEditingController();

  // Multi-Select Category Types / Offerings & Individual Pricing
  final selectedCategoryTypes = <String>[].obs;
  final typePriceControllers = <String, TextEditingController>{}.obs;

  void toggleCategoryType(String typeName) {
    if (selectedCategoryTypes.contains(typeName)) {
      selectedCategoryTypes.remove(typeName);
      typePriceControllers[typeName]?.dispose();
      typePriceControllers.remove(typeName);
    } else {
      selectedCategoryTypes.add(typeName);
      typePriceControllers[typeName] = TextEditingController();
    }
  }

  void addCustomCategoryType(String customTypeName, {String initialPrice = ''}) {
    final trimmed = customTypeName.trim();
    if (trimmed.isEmpty) return;
    if (!selectedCategoryTypes.contains(trimmed)) {
      selectedCategoryTypes.add(trimmed);
      typePriceControllers[trimmed] = TextEditingController(text: initialPrice);
    }
  }

  // -------------------------------------------------------------
  // STEP 3: IMAGES & VIDEOS
  // -------------------------------------------------------------
  final selectedThumbnailImage = Rxn<XFile>();
  final existingThumbnailUrl = RxnString();

  final selectedCoverImage = Rxn<XFile>();
  final existingCoverUrl = RxnString();

  final selectedGalleryImages = <XFile>[].obs; // Max 20
  final existingGalleryUrls = <String>[].obs;

  final selectedVideos = <XFile>[].obs; // Max 5
  final existingVideoUrls = <String>[].obs;

  // -------------------------------------------------------------
  // STEP 4: DOCUMENTS
  // -------------------------------------------------------------
  final aadhaarDoc = Rxn<XFile>();
  final existingAadhaarUrl = RxnString();

  final aadhaarFrontDoc = Rxn<XFile>();
  final existingAadhaarFrontUrl = RxnString();

  final aadhaarBackDoc = Rxn<XFile>();
  final existingAadhaarBackUrl = RxnString();

  final panDoc = Rxn<XFile>();
  final existingPanUrl = RxnString();

  final businessProofDoc = Rxn<XFile>();
  final existingBusinessProofUrl = RxnString();

  final gstDoc = Rxn<XFile>();
  final existingGstUrl = RxnString();

  final shopLicenseDoc = Rxn<XFile>();
  final existingShopLicenseUrl = RxnString();

  final addressProofDoc = Rxn<XFile>();
  final existingAddressProofUrl = RxnString();

  final chequeDoc = Rxn<XFile>();
  final existingChequeUrl = RxnString();

  // -------------------------------------------------------------
  // STEP 5: BUSINESS SETTINGS (TIMINGS)
  // -------------------------------------------------------------
  final weeklyTimings = <String, DayTiming>{
    'Monday': DayTiming(),
    'Tuesday': DayTiming(),
    'Wednesday': DayTiming(),
    'Thursday': DayTiming(),
    'Friday': DayTiming(),
    'Saturday': DayTiming(),
    'Sunday': DayTiming(isWeeklyOff: true),
  }.obs;

  // -------------------------------------------------------------
  // STEP 6: BOOKING SETTINGS
  // -------------------------------------------------------------
  final advanceBookingPercentController = TextEditingController(text: '20');
  final cancellationPolicyController = TextEditingController();
  final refundPolicyController = TextEditingController();
  final instantBookingEnabled = true.obs;
  final whatsappBookingEnabled = true.obs;
  final callBookingEnabled = true.obs;

  // -------------------------------------------------------------
  // STEP 7: REVIEW & SUBMIT
  // -------------------------------- agreed terms
  final acceptedTerms = false.obs;

  final isEditMode = false.obs;
  final editSpaceId = RxnInt();

  // Active Category's Form Fields
  Map<String, String> get activeCategoryFormFields {
    if (selectedCategoryId.value == null) return {};
    final cat = categories.firstWhereOrNull((c) => c['id'] == selectedCategoryId.value);
    if (cat == null) return {};
    final ff = cat['form_fields'];
    if (ff == null || ff is! Map) return {};
    return Map<String, String>.from(ff.map((k, v) => MapEntry(k.toString(), v.toString())));
  }

  List<Map<String, dynamic>> get currentSubcategories {
    if (selectedCategoryId.value == null) return [];
    final cat = categories.firstWhereOrNull((c) => c['id'] == selectedCategoryId.value);
    if (cat == null || cat['subcategories'] == null || cat['subcategories'] is! List) return [];
    return List<Map<String, dynamic>>.from(cat['subcategories']);
  }

  static const List<String> predefinedKeys = [
    'slider_images', 'thumbnail_image', 'preparation_time', 'similar_spaces',
    'guests', 'space_size', 'rent', 'timings', 'location',
    'get_quote', 'book_tour', 'amenities', 'description',
    'starting_price', 'price',
  ];

  String? get categoryTypeKey {
    final fields = activeCategoryFormFields;
    for (final key in fields.keys) {
      final keyLower = key.toLowerCase();
      if (keyLower.contains('type') || keyLower.contains('flavour') || keyLower.contains('flavor') || keyLower.contains('service') || keyLower.contains('style') || keyLower.contains('cake') || keyLower.contains('photo') || keyLower.contains('dress') || keyLower.contains('vehicle') || keyLower.contains('car') || keyLower.contains('pooja') || keyLower.contains('puja')) {
        return key;
      }
    }
    return null;
  }

  String get categoryTypeLabel {
    final key = categoryTypeKey;
    if (key != null && activeCategoryFormFields[key] != null) {
      return activeCategoryFormFields[key]!;
    }
    final cat = categories.firstWhereOrNull((c) => c['id'] == selectedCategoryId.value);
    final catName = cat?['name']?.toString() ?? 'Service';
    return '$catName Types & Rates';
  }

  List<String> get availableCategoryTypes {
    if (selectedCategoryId.value == null) return [];
    final cat = categories.firstWhereOrNull((c) => c['id'] == selectedCategoryId.value);
    if (cat == null) return [];
    final catName = cat['name'].toString().toLowerCase();

    if (catName.contains('cake') || catName.contains('bakery')) {
      return ['Black Forest', 'Chocolate Truffle', 'Red Velvet', 'Pineapple', 'Butterscotch', 'Fresh Fruit Cake', 'Birthday Cake', 'Wedding Designer Cake', 'Photo Cake', 'Eggless Cake'];
    } else if (catName.contains('photo') || catName.contains('studio')) {
      return ['Wedding Photography', 'Pre Wedding', 'Candid Photography', 'Traditional Photography', 'Cinematic Shoot', 'Drone Photography', 'Baby Shoot', 'Maternity Shoot', 'Corporate Shoot', 'Fashion Shoot'];
    } else if (catName.contains('anchor') || catName.contains('emcee')) {
      return ['Wedding Sangeet', 'Reception', 'Sangeet & Garba', 'Corporate Event', 'Birthday Party', 'Kids Event', 'College Event'];
    } else if (catName.contains('dj') || catName.contains('sound') || catName.contains('music')) {
      return ['DJ Setup', 'Live Band', 'Sound System', 'Light & Sound Setup', 'DJ + Sound + LED Wall'];
    } else if (catName.contains('banquet') || catName.contains('hall') || catName.contains('marriage hall')) {
      return ['Main Grand AC Banquet', 'Outdoor Lawn', 'Indoor Hall', 'AC Hall', 'Non AC Hall', 'Luxury Hall', 'Party Hall'];
    } else if (catName.contains('decor') || catName.contains('decorator') || catName.contains('theme')) {
      return ['Royal Floral Theme', 'Wedding Decoration', 'Reception Decoration', 'Haldi & Mehndi Setup', 'Birthday Theme Decor', 'Baby Shower Decor', 'Corporate Theme', 'Balloon & Floral Decor', 'Mandap Decoration'];
    } else if (catName.contains('planner') || catName.contains('event')) {
      return ['Full Wedding Management', 'Day-of Coordination', 'Birthday Party Planning', 'Anniversary Management', 'Engagement Planning', 'Corporate Event Planning'];
    } else if (catName.contains('mehndi') || catName.contains('mehendi')) {
      return ['Bridal Mehndi', 'Arabic Mehndi', 'Indo Arabic Mehndi', 'Traditional Mehndi', 'Portrait Mehndi', 'Minimalist Mehndi', 'Family / Sider Mehndi'];
    } else if (catName.contains('hotel')) {
      return ['Deluxe AC Room', 'Super Deluxe Room', 'Executive Suite', 'Standard AC Room', 'Luxury Suite', 'Family Room'];
    } else if (catName.contains('resort')) {
      return ['Luxury Villa', 'Pool Resort Cottage', 'Wedding Resort Suite', 'Nature Cottage', 'Deluxe Resort Room'];
    } else if (catName.contains('farm') || catName.contains('lawn') || catName.contains('party plot')) {
      return ['Wedding Farm Plot', 'Grand Party Plot', 'Garden & Lawn', 'Poolside Plot', 'Outdoor Farmhouse'];
    } else if (catName.contains('makeup') || catName.contains('make up') || catName.contains('make-up') || catName.contains('mua')) {
      return ['Bridal Makeup', 'Party Makeup', 'HD Makeup', 'Airbrush Makeup', 'Groom Makeup', 'Hair Styling & Draping', 'Saree Draping'];
    } else if (catName.contains('cater') || catName.contains('food')) {
      return ['Pure Veg Standard', 'Premium Gujarati Thali', 'Punjabi Feast', 'Jain Special Thali', 'Multi Cuisine Live Counter', 'Chinese & Continental', 'South Indian Feast'];
    } else if (catName.contains('invitation') || catName.contains('card')) {
      return ['Wedding Box Invitation', 'Acrylic Royal Card', 'Digital Video Invite', 'Laser Cut Invitation', 'Classic Printed Card'];
    } else if (catName.contains('jewel') || catName.contains('ornament')) {
      return ['Bridal Kundan Set', 'Diamond Choker Set', 'Temple Jewellery Set', 'Polki Jewellery Set', 'Artificial Bridal Set'];
    } else if (catName.contains('design') || catName.contains('wear') || catName.contains('boutique') || catName.contains('dress')) {
      return ['Bridal Designer Lehenga', 'Groom Royal Sherwani', 'Sider / Bridesmaid Lehenga', 'Custom Designer Gown', 'Indo Western Sherwani'];
    } else if (catName.contains('car') || catName.contains('buggy') || catName.contains('vehicle')) {
      return ['Vintage Royal Car', 'Luxury Sedan (BMW/Audi)', 'Royal Horse Buggy', 'Open Luxury Car', 'Luxury SUV (Fortuner)'];
    } else if (catName.contains('pandit') || catName.contains('pooja') || catName.contains('puja')) {
      return ['Wedding Ceremony Pooja', 'Grih Pravesh Pooja', 'Satyanarayan Katha', 'Vastu Shanti Pooja', 'Mundan Ceremony', 'Engagement Pooja'];
    }

    return ['Standard Option', 'Premium Option', 'Custom Package'];
  }

  bool isFieldEnabled(String key) {
    final fields = activeCategoryFormFields;
    if (fields.isEmpty) return true; // Show standard fields if category doesn't customize
    return fields.containsKey(key);
  }

  String fieldLabel(String key, String defaultLabel) {
    return activeCategoryFormFields[key] ?? defaultLabel;
  }

  List<MapEntry<String, String>> get customFields {
    final fields = activeCategoryFormFields;
    final typeKey = categoryTypeKey;
    return fields.entries
        .where((e) => !predefinedKeys.contains(e.key) &&
            e.key != typeKey &&
            !e.key.toLowerCase().contains('starting_price') &&
            !e.key.toLowerCase().contains('price') &&
            !e.key.toLowerCase().contains('rent'))
        .toList();
  }

  List<String>? getDropdownOptions(String key) {
    final keyLower = key.toLowerCase();
    
    if (keyLower == 'gender' || keyLower == 'male_female') return ['Male', 'Female'];
    if (keyLower.contains('allow') || keyLower.contains('available') || keyLower.contains('included') || keyLower.contains('home_service') || keyLower.contains('home_delivery') || keyLower.contains('trial')) {
      // Exclude fields that might contain these words but are not yes/no questions
      if (!keyLower.contains('time') && !keyLower.contains('limit') && !keyLower.contains('price') && !keyLower.contains('charge')) {
        return ['Yes', 'No'];
      }
    }
    
    final isTypeKey = keyLower.contains('type') ||
        keyLower.contains('service') ||
        keyLower.contains('style') ||
        keyLower.contains('category') ||
        keyLower.contains('kind') ||
        keyLower.contains('makeup') ||
        keyLower.contains('shoot') ||
        keyLower.contains('hall') ||
        keyLower.contains('decoration') ||
        keyLower.contains('event') ||
        keyLower.contains('hotel') ||
        keyLower.contains('resort') ||
        keyLower.contains('farm') ||
        keyLower.contains('food') ||
        keyLower.contains('cake') ||
        keyLower.contains('card') ||
        keyLower.contains('jewel') ||
        keyLower.contains('dress') ||
        keyLower.contains('vehicle') ||
        keyLower.contains('car') ||
        keyLower.contains('pooja') ||
        keyLower.contains('puja');

    if (isTypeKey) {
      final cat = categories.firstWhereOrNull((c) => c['id'] == selectedCategoryId.value);
      if (cat != null) {
        final catName = cat['name'].toString().toLowerCase();
        if (catName.contains('photo')) {
          return ['Wedding Photographer', 'Pre Wedding', 'Candid Photography', 'Traditional Photography', 'Cinematic Shoot', 'Drone Photography', 'Baby Shoot', 'Maternity Shoot', 'Corporate Shoot', 'Fashion Shoot', 'Product Shoot', 'Other'];
        } else if (catName.contains('anchor')) {
          return ['Wedding', 'Reception', 'Sangeet', 'Garba', 'Corporate Event', 'Birthday', 'Kids Event', 'College Event', 'Other'];
        } else if (catName.contains('dj') || catName.contains('sound') || catName.contains('band')) {
          return ['DJ', 'Live Band', 'Sound System', 'Light Setup', 'DJ + Sound', 'DJ + Sound + LED', 'Other'];
        } else if (catName.contains('banquet') || catName.contains('hall')) {
          return ['Indoor', 'Outdoor', 'Indoor + Outdoor', 'AC Hall', 'Non AC Hall', 'Luxury Hall', 'Party Hall', 'Marriage Hall'];
        } else if (catName.contains('decor')) {
          return ['Wedding Decoration', 'Reception Decoration', 'Haldi Decoration', 'Mehndi Decoration', 'Birthday Decoration', 'Baby Shower', 'Corporate Decoration', 'Theme Decoration', 'Balloon Decoration', 'Mandap Decoration', 'Floral Decoration', 'Other'];
        } else if (catName.contains('planner') || catName.contains('event')) {
          return ['Wedding', 'Birthday', 'Anniversary', 'Engagement', 'Baby Shower', 'Corporate Event', 'Garba', 'Other'];
        } else if (catName.contains('mehndi') || catName.contains('mehendi')) {
          return ['Bridal', 'Arabic', 'Indo Arabic', 'Traditional', 'Portrait', 'Minimal', 'Kids', 'Other'];
        } else if (catName.contains('hotel')) {
          return ['3 Star', '4 Star', '5 Star', 'Budget Hotel', 'Luxury Hotel', 'Boutique Hotel', 'Business Hotel', 'Other'];
        } else if (catName.contains('resort')) {
          return ['Luxury Resort', 'Wedding Resort', 'Pool Resort', 'Nature Resort', 'Farm Resort', 'Family Resort', 'Other'];
        } else if (catName.contains('farm') || catName.contains('lawn') || catName.contains('party plot')) {
          return ['Wedding Farm', 'Party Plot', 'Garden', 'Lawn', 'Outdoor Venue', 'Other'];
        } else if (catName.contains('makeup') || catName.contains('make up') || catName.contains('make-up') || catName.contains('mua')) {
          return ['Bridal Makeup', 'Party Makeup', 'HD Makeup', 'Airbrush Makeup', 'Groom Makeup', 'Hair Styling', 'Saree Draping', 'Other'];
        } else if (catName.contains('cater') || catName.contains('food')) {
          return ['Veg', 'Non Veg', 'Jain', 'Gujarati', 'Punjabi', 'Chinese', 'South Indian', 'Multi Cuisine', 'Live Counter', 'Other'];
        } else if (catName.contains('cake') || catName.contains('bakery')) {
          return ['Wedding Cake', 'Birthday Cake', 'Designer Cake', 'Theme Cake', 'Eggless Cake', 'Photo Cake', 'Other'];
        } else if (catName.contains('invitation') || catName.contains('card')) {
          return ['Printed Cards', 'Digital Card', 'Video Invitation', 'Box Invitation', 'Acrylic Invitation', 'Other'];
        } else if (catName.contains('jewel')) {
          return ['Gold', 'Diamond', 'Silver', 'Artificial Jewellery', 'Bridal Jewellery', 'Rental Jewellery', 'Other'];
        } else if (catName.contains('design') || catName.contains('wear') || catName.contains('boutique')) {
          return ['Bridal Dress', 'Lehenga', 'Sherwani', 'Blouse', 'Kids Wear', 'Custom Design', 'Rental Dress', 'Other'];
        } else if (catName.contains('car') || catName.contains('buggy') || catName.contains('vehicle')) {
          return ['Luxury Car', 'Vintage Car', 'Buggy', 'Horse Buggy', 'Wedding Car', 'Self Drive', 'With Driver', 'Other'];
        } else if (catName.contains('pandit') || catName.contains('pooja') || catName.contains('puja')) {
          return ['Wedding', 'Engagement', 'Grih Pravesh', 'Satyanarayan Katha', 'Vastu Pooja', 'Mundan', 'Naming Ceremony', 'Other'];
        }
      }
      return ['Option 1', 'Option 2', 'Other'];
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map) {
      isEditMode.value = true;
      editSpaceId.value = args['id'];
      existingThumbnailUrl.value = args['thumbnail_image'];
      existingCoverUrl.value = args['cover_image'];
      
      existingAadhaarUrl.value = args['aadhaar_card'];
      existingAadhaarFrontUrl.value = args['aadhaar_card_front'] ?? args['aadhaar_card'];
      existingAadhaarBackUrl.value = args['aadhaar_card_back'];
      existingPanUrl.value = args['pan_card'];
      existingBusinessProofUrl.value = args['business_proof'];
      existingGstUrl.value = args['gst_certificate'];
      existingShopLicenseUrl.value = args['shop_license'];
      existingAddressProofUrl.value = args['address_proof'];
      existingChequeUrl.value = args['cancelled_cheque'];

      titleController.text = args['title'] ?? '';
      businessNameController.text = args['business_name'] ?? '';
      ownerNameController.text = args['owner_name'] ?? '';
      mobileController.text = args['phone_number'] ?? args['mobile'] ?? '';
      whatsappController.text = args['whatsapp_number'] ?? '';
      emailController.text = args['email_address'] ?? args['email'] ?? '';
      cityController.text = args['city'] ?? '';
      areaController.text = args['area'] ?? '';
      addressController.text = args['address'] ?? '';
      googleMapController.text = args['google_map_location'] ?? '';
      experienceController.text = (args['experience'] ?? '').toString();
      priceController.text = (args['space_rent'] ?? args['starting_price'] ?? args['price_per_day'] ?? '').toString();
      descriptionController.text = args['description'] ?? args['about_business'] ?? '';

      sizeController.text = (args['space_size'] ?? '').toString();
      maxGuestController.text = (args['max_guest'] ?? '').toString();
      minGuestController.text = (args['min_guest'] ?? '').toString();

      advanceBookingPercentController.text = (args['advance_booking_percent'] ?? '20').toString();
      cancellationPolicyController.text = args['cancellation_policy'] ?? '';
      refundPolicyController.text = args['refund_policy'] ?? '';

      if (args['instant_booking'] != null) instantBookingEnabled.value = args['instant_booking'] == 1 || args['instant_booking'] == true;
      if (args['whatsapp_booking'] != null) whatsappBookingEnabled.value = args['whatsapp_booking'] == 1 || args['whatsapp_booking'] == true;
      if (args['call_booking'] != null) callBookingEnabled.value = args['call_booking'] == 1 || args['call_booking'] == true;

      if (args['space_category_id'] != null) {
        _initialCategoryId = int.tryParse(args['space_category_id'].toString());
        selectedCategoryId.value = _initialCategoryId;
      }
      if (args['sub_category_id'] != null || args['subcategory_id'] != null) {
        selectedSubcategoryId.value = int.tryParse((args['sub_category_id'] ?? args['subcategory_id']).toString());
      }
      if (args['space_type'] != null) {
        selectedSpaceType.value = int.tryParse(args['space_type'].toString()) ?? 1;
      }
      if (args['slider_images'] != null) {
        final sliders = args['slider_images'];
        if (sliders is List) {
          final imagesList = <String>[];
          final videosList = <String>[];
          for (var item in sliders) {
            final str = item.toString();
            final lower = str.toLowerCase();
            if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.mkv') || lower.endsWith('.webm') || lower.contains('video')) {
              videosList.add(str);
            } else {
              imagesList.add(str);
            }
          }
          existingGalleryUrls.value = imagesList;
          if (videosList.isNotEmpty) {
            existingVideoUrls.value = videosList;
          }
        }
      }
      final rawVideos = args['videos'] ?? args['video_urls'] ?? args['video_files'] ?? args['gallery_videos'] ?? args['video'];
      if (rawVideos != null) {
        if (rawVideos is List) {
          final list = rawVideos.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
          for (var item in list) {
            if (!existingVideoUrls.contains(item)) {
              existingVideoUrls.add(item);
            }
          }
        } else if (rawVideos is String && rawVideos.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(rawVideos);
            if (decoded is List) {
              for (var item in decoded) {
                final str = item.toString();
                if (!existingVideoUrls.contains(str)) {
                  existingVideoUrls.add(str);
                }
              }
            } else if (!existingVideoUrls.contains(rawVideos.trim())) {
              existingVideoUrls.add(rawVideos.trim());
            }
          } catch (_) {
            if (!existingVideoUrls.contains(rawVideos.trim())) {
              existingVideoUrls.add(rawVideos.trim());
            }
          }
        }
      }
      dynamic rawCustom = args['custom_fields'];
      if (rawCustom is String && rawCustom.trim().isNotEmpty) {
        try {
          rawCustom = jsonDecode(rawCustom);
        } catch (_) {}
      }
      Map<String, dynamic> savedCustom = {};
      if (rawCustom != null && rawCustom is Map) {
        savedCustom = Map<String, dynamic>.from(rawCustom);
      }
      _initialCustomFields.addAll(savedCustom);
      savedCustom.forEach((key, value) {
        customFieldControllers[key] = TextEditingController(text: value.toString());
      });

      // Restore type_pricing map and selected types
      dynamic rawTp = savedCustom['type_pricing'] ?? args['type_pricing'];
      if (rawTp is String && rawTp.trim().isNotEmpty) {
        try { rawTp = jsonDecode(rawTp); } catch (_) {}
      }
      if (rawTp is Map) {
        rawTp.forEach((k, v) {
          final typeName = k.toString().trim();
          if (typeName.isNotEmpty) {
            _initialTypePricing[typeName] = v;
          }
        });
      }

      dynamic rawSt = savedCustom['selected_types'] ?? args['selected_types'];
      if (rawSt is String && rawSt.trim().isNotEmpty) {
        try { rawSt = jsonDecode(rawSt); } catch (_) {}
      }
      if (rawSt is List) {
        for (var item in rawSt) {
          final typeName = item.toString().trim();
          if (typeName.isNotEmpty && !_initialSelectedTypes.contains(typeName)) {
            _initialSelectedTypes.add(typeName);
          }
        }
      }

      _restoreTypePricing();
      // Helper to parse timings map & weekly_off from server payload
      dynamic rawTimings = args['business_timings'] ?? args['timings'] ?? args['weekly_timings'] ?? args['custom_fields']?['business_timings'] ?? args['custom_fields']?['timings'];
      if (rawTimings is String && rawTimings.trim().isNotEmpty) {
        try { rawTimings = jsonDecode(rawTimings); } catch (_) {}
      }

      if (rawTimings is Map) {
        rawTimings.forEach((k, v) {
          final dayKey = k.toString();
          String? matchedKey;
          for (final wKey in weeklyTimings.keys) {
            if (wKey.toLowerCase() == dayKey.toLowerCase()) {
              matchedKey = wKey;
              break;
            }
          }
          if (matchedKey != null && v is Map) {
            final open = v['open_time']?.toString() ?? v['open']?.toString() ?? '09:00 AM';
            final close = v['close_time']?.toString() ?? v['close']?.toString() ?? '09:00 PM';
            final offVal = v['is_weekly_off'] ?? v['is_off'] ?? v['weekly_off'];
            final statusVal = v['status']?.toString().toUpperCase();
            final isOpenVal = v['is_open'];

            bool isOff = false;
            if (offVal != null) {
              isOff = offVal == true || offVal == 1 || offVal == '1' || offVal == 'true';
            } else if (statusVal != null) {
              isOff = statusVal == 'OFF' || statusVal == 'CLOSED';
            } else if (isOpenVal != null) {
              isOff = isOpenVal == false || isOpenVal == 0 || isOpenVal == '0' || isOpenVal == 'false';
            }

            weeklyTimings[matchedKey] = DayTiming(
              openTime: open,
              closeTime: close,
              isWeeklyOff: isOff,
            );
          }
        });
      } else {
        dynamic weeklyOffList = args['weekly_off'] ?? args['custom_fields']?['weekly_off'];
        if (weeklyOffList is String && weeklyOffList.trim().isNotEmpty) {
          try { weeklyOffList = jsonDecode(weeklyOffList); } catch (_) {}
        }
        if (weeklyOffList is List) {
          final offDays = weeklyOffList.map((e) => e.toString().toLowerCase()).toList();
          weeklyTimings.forEach((day, dayTiming) {
            dayTiming.isWeeklyOff = offDays.contains(day.toLowerCase());
          });
        }
      }
    }
    fetchPrerequisites();

    titleController.addListener(() {
      titleText.value = titleController.text;
    });
    titleText.value = titleController.text;

    // Reset old category fields completely when category changes
    ever(selectedCategoryId, (id) {
      _resetAndRebuildCategoryFields();
    });
  }

  int? _initialCategoryId;
  final Map<String, dynamic> _initialCustomFields = {};
  final Map<String, dynamic> _initialTypePricing = {};
  final List<String> _initialSelectedTypes = [];

  void _restoreTypePricing() {
    // 1. Restore from _initialTypePricing
    if (_initialTypePricing.isNotEmpty) {
      _initialTypePricing.forEach((typeName, price) {
        if (!selectedCategoryTypes.contains(typeName)) {
          selectedCategoryTypes.add(typeName);
        }
        if (!typePriceControllers.containsKey(typeName) || typePriceControllers[typeName]!.text.isEmpty) {
          typePriceControllers[typeName]?.dispose();
          typePriceControllers[typeName] = TextEditingController(text: price.toString());
        }
      });
    }

    // 2. Restore from _initialSelectedTypes
    if (_initialSelectedTypes.isNotEmpty) {
      for (final typeName in _initialSelectedTypes) {
        if (!selectedCategoryTypes.contains(typeName)) {
          selectedCategoryTypes.add(typeName);
        }
        if (!typePriceControllers.containsKey(typeName)) {
          typePriceControllers[typeName] = TextEditingController();
        }
      }
    }

    // 3. Fallback: If in edit mode and selectedCategoryTypes is still empty,
    // but the space has a rent / starting price, auto-select matching or available type
    if (isEditMode.value && selectedCategoryTypes.isEmpty) {
      final rentText = priceController.text.trim();
      final double rentVal = double.tryParse(rentText) ?? 0;
      if (rentVal > 0) {
        String? targetType;
        for (final entry in _initialCustomFields.entries) {
          final val = entry.value?.toString().trim();
          if (val != null && val.isNotEmpty && availableCategoryTypes.contains(val)) {
            targetType = val;
            break;
          }
        }
        if (targetType == null && availableCategoryTypes.isNotEmpty) {
          targetType = availableCategoryTypes.first;
        }

        if (targetType != null) {
          if (!selectedCategoryTypes.contains(targetType)) {
            selectedCategoryTypes.add(targetType);
          }
          typePriceControllers[targetType]?.dispose();
          typePriceControllers[targetType] = TextEditingController(text: rentVal.toStringAsFixed(0));
        }
      }
    }

    selectedCategoryTypes.refresh();
    typePriceControllers.refresh();
  }

  void _resetAndRebuildCategoryFields() {
    final bool isSameAsInitial = isEditMode.value &&
        selectedCategoryId.value != null &&
        selectedCategoryId.value == _initialCategoryId;

    for (final c in customFieldControllers.values) {
      c.dispose();
    }
    customFieldControllers.clear();

    if (!isSameAsInitial) {
      for (final c in typePriceControllers.values) {
        c.dispose();
      }
      typePriceControllers.clear();
      selectedCategoryTypes.clear();
      selectedSubcategoryId.value = null;
    }

    final fields = customFields;
    for (final entry in fields) {
      final initialVal = _initialCustomFields[entry.key]?.toString() ?? '';
      customFieldControllers[entry.key] = TextEditingController(text: initialVal);
    }

    if (isSameAsInitial) {
      _restoreTypePricing();
    }

    customFieldControllers.refresh();
    selectedCategoryTypes.refresh();
    typePriceControllers.refresh();
  }

  Future<void> fetchPrerequisites() async {
    try {
      final response = await _apiService.dio.get('/vendor/space/prerequisites');
      if (response.data['status'] == true) {
        final rawCategories = response.data['data']['categories'] as List;
        categories.value = rawCategories.map((c) => Map<String, dynamic>.from(c)).toList();
        final rawAmenities = response.data['data']['amenities'] as List;
        amenities.value = rawAmenities.map((a) => Map<String, dynamic>.from(a)).toList();

        if (isEditMode.value && selectedCategoryId.value != null) {
          _resetAndRebuildCategoryFields();
        }
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to load space category prerequisites');
    } finally {
      isPrerequisitesLoading.value = false;
    }
  }

  // -------------------------------------------------------------
  // STEP 3: IMAGE & VIDEO PICKERS
  // -------------------------------------------------------------
  void pickImageWithSource({required ImageSource source, required Function(XFile) onPicked}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        onPicked(image);
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to pick image: $e');
    }
  }

  void showSourcePickerSheet(BuildContext context, {required Function(XFile) onPicked}) {
    Get.bottomSheet(
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.navyBlue),
              title: const Text('Take Photo from Camera'),
              onTap: () {
                Get.back();
                pickImageWithSource(source: ImageSource.camera, onPicked: onPicked);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.navyBlue),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Get.back();
                pickImageWithSource(source: ImageSource.gallery, onPicked: onPicked);
              },
            ),
          ],
        ),
      ),
    );
  }

  void pickThumbnailImage(BuildContext context) {
    showSourcePickerSheet(context, onPicked: (img) => selectedThumbnailImage.value = img);
  }

  void pickCoverImage(BuildContext context) {
    showSourcePickerSheet(context, onPicked: (img) => selectedCoverImage.value = img);
  }

  void pickGalleryImages() async {
    if (selectedGalleryImages.length + existingGalleryUrls.length >= 20) {
      SnackbarHelper.showError('Maximum 20 gallery images allowed');
      return;
    }
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      final remainingSlots = 20 - (selectedGalleryImages.length + existingGalleryUrls.length);
      if (images.length > remainingSlots) {
        selectedGalleryImages.addAll(images.take(remainingSlots));
        SnackbarHelper.showError('Only $remainingSlots images added. Maximum limit is 20 images.');
      } else {
        selectedGalleryImages.addAll(images);
      }
    }
  }

  void reorderGalleryImages(int oldIndex, int newIndex) {
    if (oldIndex < selectedGalleryImages.length && newIndex <= selectedGalleryImages.length) {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = selectedGalleryImages.removeAt(oldIndex);
      selectedGalleryImages.insert(newIndex, item);
    }
  }

  void removeGalleryImage(int index) {
    if (index < selectedGalleryImages.length) {
      selectedGalleryImages.removeAt(index);
    }
  }

  void removeExistingGalleryImage(int index) {
    if (index < existingGalleryUrls.length) {
      existingGalleryUrls.removeAt(index);
    }
  }

  void pickVideo() async {
    if (selectedVideos.length + existingVideoUrls.length >= 5) {
      SnackbarHelper.showError('Maximum 5 videos allowed');
      return;
    }
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      selectedVideos.add(video);
    }
  }

  void removeVideo(int index) {
    if (index < selectedVideos.length) {
      selectedVideos.removeAt(index);
    }
  }

  void removeExistingVideo(int index) {
    if (index < existingVideoUrls.length) {
      existingVideoUrls.removeAt(index);
    }
  }

  // -------------------------------------------------------------
  // STEP 4: DOCUMENT PICKERS
  // -------------------------------------------------------------
  void pickDocument(BuildContext context, Rxn<XFile> target) async {
    showSourcePickerSheet(context, onPicked: (doc) => target.value = doc);
  }

  // -------------------------------------------------------------
  // STEP VALIDATION HELPERS & NAVIGATION
  // -------------------------------------------------------------
  bool isStep1Valid() {
    if (titleController.text.trim().isEmpty) return false;
    if (selectedCategoryId.value == null) return false;
    if (mobileController.text.trim().isNotEmpty && mobileController.text.trim().length < 10) return false;
    if (emailController.text.trim().isNotEmpty && !GetUtils.isEmail(emailController.text.trim())) return false;
    return true;
  }

  bool isCustomFieldRequired(String key) {
    if (key == 'type' || key == 'property_type' || key == 'space_type' || key == 'setup_type' || key == 'gender' || key == 'male_female') return true;
    if (key.contains('price') || key.contains('charge') || key.contains('rent') || key.contains('amount') || key.contains('rate')) return true;
    return false;
  }

  bool isStep2Valid() {
    if (availableCategoryTypes.isNotEmpty) {
      if (selectedCategoryTypes.isEmpty) return false;
      for (final type in selectedCategoryTypes) {
        final ctrl = typePriceControllers[type];
        if (ctrl == null || (double.tryParse(ctrl.text.trim()) ?? 0) <= 0) {
          return false;
        }
      }
    }
    for (final entry in customFields) {
      if (isCustomFieldRequired(entry.key)) {
        final ctrl = customFieldControllers[entry.key];
        if (ctrl != null && ctrl.text.trim().isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  bool isStep3Valid() {
    return selectedThumbnailImage.value != null || existingThumbnailUrl.value != null;
  }

  bool isStep4Valid() {
    final hasAadhaarFront = aadhaarFrontDoc.value != null || existingAadhaarFrontUrl.value != null || aadhaarDoc.value != null || existingAadhaarUrl.value != null;
    final hasAadhaarBack = aadhaarBackDoc.value != null || existingAadhaarBackUrl.value != null;
    final hasPan = panDoc.value != null || existingPanUrl.value != null;
    return hasAadhaarFront && hasAadhaarBack && hasPan;
  }

  bool isStep5Valid() => true;

  bool isStep6Valid() => true;

  bool isStep7Valid() {
    return isStep1Valid() && isStep2Valid() && isStep3Valid() && isStep4Valid() && isStep6Valid() && acceptedTerms.value;
  }

  void toggleAmenity(int id) {
    if (selectedAmenities.contains(id)) {
      selectedAmenities.remove(id);
    } else {
      selectedAmenities.add(id);
    }
  }

  void nextStep() {
    // Validate Current Step
    switch (currentStep.value) {
      case 0:
        if (!isStep1Valid()) {
          if (titleController.text.trim().isEmpty) {
            SnackbarHelper.showError('Space Title is required');
          } else if (selectedCategoryId.value == null) {
            SnackbarHelper.showError('Please select a Category');
          } else if (mobileController.text.trim().isNotEmpty && mobileController.text.trim().length < 10) {
            SnackbarHelper.showError('Please enter a valid 10-digit mobile number');
          } else if (emailController.text.trim().isNotEmpty && !GetUtils.isEmail(emailController.text.trim())) {
            SnackbarHelper.showError('Please enter a valid email address');
          }
          return;
        }
        break;
      case 1:
        if (!isStep2Valid()) {
          if (availableCategoryTypes.isNotEmpty && selectedCategoryTypes.isEmpty) {
            SnackbarHelper.showError('Please select at least one $categoryTypeLabel');
            return;
          }
          for (final type in selectedCategoryTypes) {
            final ctrl = typePriceControllers[type];
            if (ctrl == null || (double.tryParse(ctrl.text.trim()) ?? 0) <= 0) {
              SnackbarHelper.showError('Please enter a valid rate for $type');
              return;
            }
          }
          for (final entry in customFields) {
            if (isCustomFieldRequired(entry.key)) {
              final ctrl = customFieldControllers[entry.key];
              if (ctrl != null && ctrl.text.trim().isEmpty) {
                SnackbarHelper.showError('${entry.value} is required');
                return;
              }
            }
          }
        }
        break;
      case 2:
        if (!isStep3Valid()) {
          SnackbarHelper.showError('Thumbnail Image is required');
          return;
        }
        break;
      case 3:
        if (!isStep4Valid()) {
          final hasFront = aadhaarFrontDoc.value != null || existingAadhaarFrontUrl.value != null || aadhaarDoc.value != null || existingAadhaarUrl.value != null;
          final hasBack = aadhaarBackDoc.value != null || existingAadhaarBackUrl.value != null;
          if (!hasFront) {
            SnackbarHelper.showError('Aadhaar Card (Front) is required');
          } else if (!hasBack) {
            SnackbarHelper.showError('Aadhaar Card (Back) is required');
          } else if (panDoc.value == null && existingPanUrl.value == null) {
            SnackbarHelper.showError('PAN Card document is required');
          }
          return;
        }
        break;
      case 4:
        break;
      case 5:
        break;
      case 6:
        if (!acceptedTerms.value) {
          SnackbarHelper.showError('Please accept the Terms & Conditions');
          return;
        }
        submitForm();
        return;
    }

    if (currentStep.value < 6) {
      currentStep.value++;
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 6) {
      currentStep.value = step;
    }
  }

  // -------------------------------------------------------------
  // SUBMISSION LOGIC
  // -------------------------------------------------------------
  Future<void> submitForm() async {
    if (!isStep7Valid()) {
      SnackbarHelper.showError('Please complete all required fields and accept terms before submitting.');
      return;
    }

    isLoading.value = true;
    try {
      // Calculate min price and type pricing map from selectedCategoryTypes
      double minPrice = 0;
      final Map<String, dynamic> typePricingMap = {};
      for (final type in selectedCategoryTypes) {
        final ctrl = typePriceControllers[type];
        final p = double.tryParse(ctrl?.text.trim() ?? '') ?? 0;
        if (p > 0) {
          typePricingMap[type] = p;
          if (minPrice == 0 || p < minPrice) {
            minPrice = p;
          }
        }
      }
      if (minPrice == 0 && priceController.text.trim().isNotEmpty) {
        minPrice = double.tryParse(priceController.text.trim()) ?? 0;
      }

      var formData = dio.FormData.fromMap({
        'title': titleController.text.trim(),
        'business_name': businessNameController.text.trim(),
        'owner_name': ownerNameController.text.trim(),
        'phone_number': mobileController.text.trim(),
        'whatsapp_number': whatsappController.text.trim(),
        'email_address': emailController.text.trim(),
        'city': cityController.text.trim(),
        'area': areaController.text.trim(),
        'address': addressController.text.trim(),
        'google_map_location': googleMapController.text.trim(),
        'experience': experienceController.text.trim(),
        'space_rent': minPrice > 0 ? minPrice.toString() : '0',
        'starting_price': minPrice > 0 ? minPrice.toString() : '0',
        'description': descriptionController.text.trim(),
        'category_id': selectedCategoryId.value.toString(),
        'space_category_id': selectedCategoryId.value.toString(),
        if (selectedSubcategoryId.value != null) ...{
          'sub_category_id': selectedSubcategoryId.value.toString(),
          'subcategory_id': selectedSubcategoryId.value.toString(),
        },
        'space_type': selectedSpaceType.value.toString(),
        'space_size': sizeController.text.trim().isEmpty ? '0' : sizeController.text.trim(),
        'max_guest': maxGuestController.text.trim().isEmpty ? '0' : maxGuestController.text.trim(),
        'min_guest': minGuestController.text.trim().isEmpty ? '0' : minGuestController.text.trim(),
        'advance_booking_percent': advanceBookingPercentController.text.trim(),
        'cancellation_policy': cancellationPolicyController.text.trim(),
        'refund_policy': refundPolicyController.text.trim(),
        'instant_booking': instantBookingEnabled.value ? 1 : 0,
        'whatsapp_booking': whatsappBookingEnabled.value ? 1 : 0,
        'call_booking': callBookingEnabled.value ? 1 : 0,
      });

      // Weekly Timings JSON & Form Payload
      final timingMap = weeklyTimings.map((k, v) => MapEntry(k, v.toJson()));
      final jsonTimings = jsonEncode(timingMap);

      formData.fields.add(MapEntry('business_timings', jsonTimings));
      formData.fields.add(MapEntry('timings', jsonTimings));
      formData.fields.add(MapEntry('weekly_timings', jsonTimings));
      formData.fields.add(MapEntry('custom_fields[business_timings]', jsonTimings));

      // Build weekly_off array for days that are OFF
      final offDays = weeklyTimings.entries
          .where((e) => e.value.isWeeklyOff)
          .map((e) => e.key)
          .toList();
      formData.fields.add(MapEntry('weekly_off', jsonEncode(offDays)));

      // Also send nested day-by-day parameters
      weeklyTimings.forEach((day, dt) {
        formData.fields.add(MapEntry('business_timings[$day][open_time]', dt.openTime));
        formData.fields.add(MapEntry('business_timings[$day][close_time]', dt.closeTime));
        formData.fields.add(MapEntry('business_timings[$day][is_weekly_off]', dt.isWeeklyOff ? '1' : '0'));
        formData.fields.add(MapEntry('timings[$day][open_time]', dt.openTime));
        formData.fields.add(MapEntry('timings[$day][close_time]', dt.closeTime));
        formData.fields.add(MapEntry('timings[$day][is_weekly_off]', dt.isWeeklyOff ? '1' : '0'));
      });

      // Amenities
      for (var i = 0; i < selectedAmenities.length; i++) {
        formData.fields.add(MapEntry('amenities[$i]', selectedAmenities[i].toString()));
      }

      // Custom fields
      customFieldControllers.forEach((key, controller) {
        if (controller.text.trim().isNotEmpty) {
          formData.fields.add(MapEntry('custom_fields[$key]', controller.text.trim()));
        }
      });

      // Type pricing & selected types
      if (typePricingMap.isNotEmpty) {
        formData.fields.add(MapEntry('type_pricing', jsonEncode(typePricingMap)));
        formData.fields.add(MapEntry('selected_types', jsonEncode(selectedCategoryTypes.toList())));
        formData.fields.add(MapEntry('custom_fields[type_pricing]', jsonEncode(typePricingMap)));
        formData.fields.add(MapEntry('custom_fields[selected_types]', jsonEncode(selectedCategoryTypes.toList())));
      }

      // Files: Thumbnail & Cover
      if (selectedThumbnailImage.value != null) {
        formData.files.add(MapEntry(
          'thumbnail_image',
          await dio.MultipartFile.fromFile(selectedThumbnailImage.value!.path, filename: 'thumb.jpg'),
        ));
      }
      if (selectedCoverImage.value != null) {
        formData.files.add(MapEntry(
          'cover_image',
          await dio.MultipartFile.fromFile(selectedCoverImage.value!.path, filename: 'cover.jpg'),
        ));
      }

      // Gallery Images
      for (int i = 0; i < selectedGalleryImages.length; i++) {
        formData.files.add(MapEntry(
          'slider_images[]',
          await dio.MultipartFile.fromFile(
            selectedGalleryImages[i].path,
            filename: 'gallery_$i.jpg',
          ),
        ));
      }

      // Videos Upload (Multiple field key fallback support)
      for (int i = 0; i < selectedVideos.length; i++) {
        final videoPath = selectedVideos[i].path;
        final extension = videoPath.split('.').last;
        final mimeFileName = 'video_$i.$extension';

        formData.files.add(MapEntry(
          'slider_images[]',
          await dio.MultipartFile.fromFile(videoPath, filename: mimeFileName),
        ));
        formData.files.add(MapEntry(
          'videos[]',
          await dio.MultipartFile.fromFile(videoPath, filename: mimeFileName),
        ));
        formData.files.add(MapEntry(
          'video_files[]',
          await dio.MultipartFile.fromFile(videoPath, filename: mimeFileName),
        ));
        formData.files.add(MapEntry(
          'video',
          await dio.MultipartFile.fromFile(videoPath, filename: mimeFileName),
        ));
      }

      // Documents
      if (aadhaarFrontDoc.value != null) {
        formData.files.add(MapEntry('aadhaar_card_front', await dio.MultipartFile.fromFile(aadhaarFrontDoc.value!.path, filename: 'aadhaar_front.jpg')));
      } else if (aadhaarDoc.value != null) {
        formData.files.add(MapEntry('aadhaar_card_front', await dio.MultipartFile.fromFile(aadhaarDoc.value!.path, filename: 'aadhaar_front.jpg')));
      }
      if (aadhaarBackDoc.value != null) {
        formData.files.add(MapEntry('aadhaar_card_back', await dio.MultipartFile.fromFile(aadhaarBackDoc.value!.path, filename: 'aadhaar_back.jpg')));
      }
      if (panDoc.value != null) {
        formData.files.add(MapEntry('pan_card', await dio.MultipartFile.fromFile(panDoc.value!.path, filename: 'pan.jpg')));
      }
      if (businessProofDoc.value != null) {
        formData.files.add(MapEntry('business_proof', await dio.MultipartFile.fromFile(businessProofDoc.value!.path, filename: 'biz_proof.jpg')));
      }
      if (gstDoc.value != null) {
        formData.files.add(MapEntry('gst_certificate', await dio.MultipartFile.fromFile(gstDoc.value!.path, filename: 'gst.jpg')));
      }
      if (shopLicenseDoc.value != null) {
        formData.files.add(MapEntry('shop_license', await dio.MultipartFile.fromFile(shopLicenseDoc.value!.path, filename: 'license.jpg')));
      }
      if (addressProofDoc.value != null) {
        formData.files.add(MapEntry('address_proof', await dio.MultipartFile.fromFile(addressProofDoc.value!.path, filename: 'address_proof.jpg')));
      }
      if (chequeDoc.value != null) {
        formData.files.add(MapEntry('bank_proof', await dio.MultipartFile.fromFile(chequeDoc.value!.path, filename: 'bank_proof.jpg')));
      }

      final endpoint = isEditMode.value
          ? '/vendor/space/update/${editSpaceId.value}'
          : '/vendor/space/store';

      final response = await _apiService.dio.post(endpoint, data: formData);

      if (response.data['status'] == true) {
        FocusManager.instance.primaryFocus?.unfocus();
        if (Get.isRegistered<SpacesController>()) {
          Get.find<SpacesController>().fetchSpaces();
        }

        // Show Success Dialog as requested
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Column(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 56),
                const SizedBox(height: 12),
                Text(
                  isEditMode.value ? 'Space Updated Successfully!' : 'Space Added Successfully!',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: const Text(
              'Your space details have been saved to the server.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              OutlinedButton(
                onPressed: () {
                  Get.back(); // Close dialog
                  Get.until((route) => route.settings.name == '/spaces' || route.settings.name == '/dashboard');
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.navyBlue),
                ),
                child: const Text('My Spaces', style: TextStyle(color: AppColors.navyBlue)),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back(); // Close dialog
                  Get.off(() => const AddSpaceScreen()); // Reset and add another
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyBlue),
                child: const Text('+ Add Another Space'),
              ),
            ],
          ),
          barrierDismissible: false,
        );
      } else {
        SnackbarHelper.showError(response.data['message'] ?? 'Failed to save space');
      }
    } catch (e) {
      if (e is dio.DioException) {
        final msg = e.response?.data['message'] ?? e.message ?? 'Failed to save space';
        SnackbarHelper.showError('Error: $msg');
      } else {
        SnackbarHelper.showError('Error: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  void copyMondayTimingToAllDays() {
    final mon = weeklyTimings['Monday'];
    if (mon == null) return;
    weeklyTimings.forEach((day, timing) {
      if (day != 'Monday') {
        timing.openTime = mon.openTime;
        timing.closeTime = mon.closeTime;
        timing.isWeeklyOff = mon.isWeeklyOff;
      }
    });
    weeklyTimings.refresh();
    SnackbarHelper.showSuccess('Monday timings copied to all days');
  }

  @override
  void onClose() {
    titleController.dispose();
    businessNameController.dispose();
    ownerNameController.dispose();
    mobileController.dispose();
    whatsappController.dispose();
    emailController.dispose();
    cityController.dispose();
    areaController.dispose();
    addressController.dispose();
    googleMapController.dispose();
    experienceController.dispose();
    priceController.dispose();
    descriptionController.dispose();

    sizeController.dispose();
    maxGuestController.dispose();
    minGuestController.dispose();

    advanceBookingPercentController.dispose();
    cancellationPolicyController.dispose();
    refundPolicyController.dispose();

    for (final c in customFieldControllers.values) {
      c.dispose();
    }
    super.onClose();
  }
}
