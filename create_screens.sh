#!/bin/bash

function create_screen {
  local path=$1
  local class_name=$2
  local title=$3

  cat << INNER_EOF > "$path"
import 'package:flutter/material.dart';
import '../../../widgets/app_drawer.dart';

class ${class_name} extends StatelessWidget {
  const ${class_name}({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('${title}')),
      drawer: const AppDrawer(),
      body: const Center(
        child: Text('${title} - Coming Soon'),
      ),
    );
  }
}
INNER_EOF
}

# Create missing directories
mkdir -p lib/screens/holidays lib/screens/forms lib/screens/coupons
mkdir -p lib/screens/bookings/quote_requests lib/screens/bookings/tour_requests
mkdir -p lib/screens/subscription/subscription_log
mkdir -p lib/screens/withdrawals/make_request

# Create screens (adjust import paths for 1-level deep)
cat << 'INNER_EOF' > "lib/screens/holidays/holidays_screen.dart"
import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class HolidaysScreen extends StatelessWidget {
  const HolidaysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Holidays')),
      drawer: const AppDrawer(),
      body: const Center(child: Text('Holidays - Coming Soon')),
    );
  }
}
INNER_EOF

cat << 'INNER_EOF' > "lib/screens/forms/forms_screen.dart"
import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class FormsScreen extends StatelessWidget {
  const FormsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forms')),
      drawer: const AppDrawer(),
      body: const Center(child: Text('Forms - Coming Soon')),
    );
  }
}
INNER_EOF

cat << 'INNER_EOF' > "lib/screens/coupons/coupons_screen.dart"
import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class CouponsScreen extends StatelessWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coupons')),
      drawer: const AppDrawer(),
      body: const Center(child: Text('Coupons - Coming Soon')),
    );
  }
}
INNER_EOF

# Nested screens (3 levels deep)
create_screen "lib/screens/bookings/quote_requests/quote_requests_screen.dart" "QuoteRequestsScreen" "Quote Requests"
create_screen "lib/screens/bookings/tour_requests/tour_requests_screen.dart" "TourRequestsScreen" "Tour Requests"
create_screen "lib/screens/subscription/subscription_log/subscription_log_screen.dart" "SubscriptionLogScreen" "Subscription Log"
create_screen "lib/screens/withdrawals/make_request/make_request_screen.dart" "MakeRequestScreen" "Make a Request"

chmod +x create_screens.sh
./create_screens.sh
