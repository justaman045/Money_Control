import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:money_control/Components/add_transaction_widget.dart';

/// Example screen demonstrating how to use the AddTransactionWidget
/// 
/// This screen shows two tabs:
/// 1. Send Money - for outgoing transactions
/// 2. Receive Money - for incoming transactions
/// 
/// Usage:
/// Navigate to this screen from anywhere in your app:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => AddTransactionScreen()),
/// );
/// ```
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: scheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Transaction',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: scheme.primary,
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurface.withOpacity(0.6),
          labelStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.north_east),
              text: 'Send Money',
            ),
            Tab(
              icon: Icon(Icons.south_west),
              text: 'Receive Money',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Send Money Tab
          _buildTabContent(
            transactionType: 'send',
            scheme: scheme,
          ),
          // Receive Money Tab
          _buildTabContent(
            transactionType: 'receive',
            scheme: scheme,
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent({
    required String transactionType,
    required ColorScheme scheme,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Information Card
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: scheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: scheme.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    transactionType == 'send'
                        ? 'Enter details to send money. Your balance will be updated automatically.'
                        : 'Record money received from others. This will increase your balance.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: scheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Transaction Widget
          AddTransactionWidget(
            transactionType: transactionType,
          ),
        ],
      ),
    );
  }
}
