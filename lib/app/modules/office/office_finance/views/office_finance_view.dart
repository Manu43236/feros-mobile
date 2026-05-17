import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/theme/app_colors.dart';
import '../controllers/office_invoices_controller.dart';
import '../controllers/office_credit_notes_controller.dart';
import '../controllers/office_client_advances_controller.dart';
import 'office_invoices_tab.dart';
import 'office_credit_notes_tab.dart';
import 'office_client_advances_tab.dart';

class OfficeFinanceView extends StatelessWidget {
  const OfficeFinanceView({super.key});

  @override
  Widget build(BuildContext context) {
    // Register controllers for this screen's lifetime
    Get.lazyPut<OfficeInvoicesController>(() => OfficeInvoicesController());
    Get.lazyPut<OfficeCreditNotesController>(() => OfficeCreditNotesController());
    Get.lazyPut<OfficeClientAdvancesController>(() => OfficeClientAdvancesController());

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          elevation: 0,
          leading: IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: const Text(
            'Finance',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.orange,
            indicatorWeight: 3,
            labelStyle: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelStyle: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 13,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Color(0x99FFFFFF),
            tabs: [
              Tab(text: 'Invoices'),
              Tab(text: 'Credit Notes'),
              Tab(text: 'Advances'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OfficeInvoicesTab(),
            OfficeCreditNotesTab(),
            OfficeClientAdvancesTab(),
          ],
        ),
      ),
    );
  }
}
