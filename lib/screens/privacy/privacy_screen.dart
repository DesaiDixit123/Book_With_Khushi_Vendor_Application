import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../widgets/app_drawer.dart';
import 'privacy_controller.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PrivacyController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.pageContent.value.isEmpty) {
          return const Center(child: Text("No privacy policy found."));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: HtmlWidget(
            controller.pageContent.value,
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        );
      }),
    );
  }
}
