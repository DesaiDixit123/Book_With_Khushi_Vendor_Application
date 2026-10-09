import 'package:get/get.dart';
import 'app_routes.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/mobile_otp_login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/spaces/spaces_screen.dart';
import '../screens/spaces/add_space_screen.dart';
import '../screens/bookings/bookings_screen.dart';
import '../screens/subscription/subscription_screen.dart';
import '../screens/subscription/checkout/checkout_screen.dart';
import '../screens/withdrawals/withdrawals_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/privacy/privacy_screen.dart';
import '../screens/change_password/change_password_screen.dart';
import '../screens/recipient_mail/recipient_mail_screen.dart';

import '../screens/holidays/holidays_screen.dart';
import '../screens/holidays/add_holiday_screen.dart';
import '../screens/forms/forms_screen.dart';
import '../screens/forms/add_form_screen.dart';
import '../screens/forms/edit_form_screen.dart';
import '../screens/forms/manage_form_inputs_screen.dart';
import '../screens/coupons/coupons_screen.dart';
import '../screens/coupons/add_coupon_screen.dart';
import '../screens/coupons/edit_coupon_screen.dart';
import '../screens/bookings/quote_requests/quote_requests_screen.dart';
import '../screens/bookings/tour_requests/tour_requests_screen.dart';
import '../screens/subscription/subscription_log/subscription_log_screen.dart';
import '../screens/withdrawals/make_request/make_request_screen.dart';
import '../screens/spaces/services/services_screen.dart';
import '../screens/spaces/services/add_service_screen.dart';
import '../screens/check_limit/check_limit_screen.dart';
import '../screens/referral/referral_screen.dart';
import '../screens/referral/wallet_screen.dart';
import '../screens/referral/referral_history_screen.dart';
import '../screens/referral/bank_details_screen.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupScreen(),
    ),
    GetPage(
      name: AppRoutes.mobileOtpLogin,
      page: () => const MobileOtpLoginScreen(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
    ),
    GetPage(
      name: AppRoutes.spaces,
      page: () => const SpacesScreen(),
    ),
    GetPage(
      name: AppRoutes.addSpace,
      page: () => const AddSpaceScreen(),
    ),
    GetPage(
      name: AppRoutes.bookings,
      page: () => const BookingsScreen(),
    ),
    GetPage(
      name: AppRoutes.subscription,
      page: () => const SubscriptionScreen(),
    ),
    GetPage(
      name: AppRoutes.checkout,
      page: () => const CheckoutScreen(),
    ),
    GetPage(
      name: AppRoutes.withdrawals,
      page: () => const WithdrawalsScreen(),
    ),
    GetPage(
      name: AppRoutes.transactions,
      page: () => const TransactionsScreen(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsScreen(),
    ),
    GetPage(
      name: AppRoutes.privacy,
      page: () => const PrivacyScreen(),
    ),
    // Additional pages will be added here
    // Space Management
    GetPage(name: AppRoutes.holidays, page: () => const HolidaysScreen()),
    GetPage(name: AppRoutes.addHoliday, page: () => const AddHolidayScreen()),
    GetPage(name: AppRoutes.forms, page: () => const FormsScreen()),
    GetPage(name: AppRoutes.addForm, page: () => const AddFormScreen()),
    GetPage(name: AppRoutes.editForm, page: () => const EditFormScreen()),
    GetPage(name: AppRoutes.manageFormInputs, page: () => const ManageFormInputsScreen()),
    GetPage(name: AppRoutes.coupons, page: () => const CouponsScreen()),
    GetPage(name: AppRoutes.addCoupon, page: () => const AddCouponScreen()),
    GetPage(name: AppRoutes.editCoupon, page: () => const EditCouponScreen()),

    // Bookings & Requests
    GetPage(name: AppRoutes.quoteRequests, page: () => const QuoteRequestsScreen()),
    GetPage(name: AppRoutes.tourRequests, page: () => const TourRequestsScreen()),

    // Subscription
    GetPage(name: AppRoutes.subscriptionLog, page: () => const SubscriptionLogScreen()),

    // Withdrawals
    GetPage(name: AppRoutes.makeRequest, page: () => const MakeRequestScreen()),

    // Profile Settings
    GetPage(name: AppRoutes.changePassword, page: () => const ChangePasswordScreen()),
    GetPage(name: AppRoutes.recipientMail, page: () => const RecipientMailScreen()),

    // Services
    GetPage(name: AppRoutes.services, page: () => const ServicesScreen()),
    GetPage(name: AppRoutes.addService, page: () => const AddServiceScreen()),
    
    // Limits
    GetPage(name: AppRoutes.checkLimit, page: () => const CheckLimitScreen()),

    // Referral System
    GetPage(name: AppRoutes.referral, page: () => const ReferralScreen()),
    GetPage(name: AppRoutes.wallet, page: () => const WalletScreen()),
    GetPage(name: AppRoutes.referralHistory, page: () => const ReferralHistoryScreen()),
    GetPage(name: AppRoutes.bankDetails, page: () => const BankDetailsScreen()),
  ];
}
