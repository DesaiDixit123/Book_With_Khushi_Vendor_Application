import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'recipient_mail_controller.dart';
import '../../widgets/app_drawer.dart';

class RecipientMailScreen extends StatelessWidget {
  const RecipientMailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RecipientMailController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipient Mail'),
      ),
      drawer: const AppDrawer(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.fetchRecipientMail,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'All booking details & customer inquiry notifications will be sent to the email address specified below.',
                  style: TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: controller.mailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Email Address',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter email address';
                    }
                    if (!GetUtils.isEmail(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.isSaving.value ? null : controller.updateRecipientMail,
                    child: controller.isSaving.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('SAVE EMAIL'),
                  )),
                ),
              ],
            ),
          ),
        ),
      );
      }),
    );
  }
}
