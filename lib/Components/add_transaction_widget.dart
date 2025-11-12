import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:money_control/Models/transaction.dart';
import 'package:money_control/Components/colors.dart';

/// A comprehensive widget that allows users to add new transactions
/// and displays the current available balance.
/// 
/// Features:
/// - Real-time balance calculation
/// - Add transaction with amount, recipient, category, and notes
/// - Input validation
/// - Loading states
/// - Success/Error feedback
class AddTransactionWidget extends StatefulWidget {
  /// The type of transaction: 'send' or 'receive'
  final String transactionType;

  const AddTransactionWidget({
    super.key,
    this.transactionType = 'send',
  });

  @override
  State<AddTransactionWidget> createState() => _AddTransactionWidgetState();
}

class _AddTransactionWidgetState extends State<AddTransactionWidget> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();
  final _noteController = TextEditingController();
  final _categoryController = TextEditingController();
  
  bool _isLoading = false;
  bool _isCalculatingBalance = true;
  double _currentBalance = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    _noteController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  /// Calculate the current balance based on all transactions
  Future<void> _loadBalance() async {
    setState(() {
      _isCalculatingBalance = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      double balance = 0;

      // Get all sent transactions
      final sentSnaps = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('transactions')
          .where('senderId', isEqualTo: user.uid)
          .get();

      for (final doc in sentSnaps.docs) {
        final txn = TransactionModel.fromMap(doc.id, doc.data());
        balance -= txn.amount;
        balance -= txn.tax;
      }

      // Get all received transactions
      final receivedSnaps = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('transactions')
          .where('recipientId', isEqualTo: user.uid)
          .get();

      for (final doc in receivedSnaps.docs) {
        final txn = TransactionModel.fromMap(doc.id, doc.data());
        balance += txn.amount;
      }

      setState(() {
        _currentBalance = balance;
        _isCalculatingBalance = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load balance: ${e.toString()}';
        _isCalculatingBalance = false;
      });
    }
  }

  /// Add a new transaction to Firestore
  Future<void> _addTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final amount = double.parse(_amountController.text);
      final recipient = _recipientController.text.trim();
      final note = _noteController.text.trim();
      final category = _categoryController.text.trim();

      // Check if sender has sufficient balance for send transactions
      if (widget.transactionType == 'send' && amount > _currentBalance) {
        throw Exception('Insufficient balance');
      }

      final transaction = TransactionModel(
        id: '', // Will be set by Firestore
        senderId: widget.transactionType == 'send' ? user.uid : recipient,
        recipientId: widget.transactionType == 'send' ? recipient : user.uid,
        recipientName: recipient,
        amount: amount,
        currency: '₹',
        tax: 0.0,
        note: note.isEmpty ? null : note,
        category: category.isEmpty ? null : category,
        date: DateTime.now(),
        status: 'success',
        createdAt: Timestamp.now(),
      );

      // Add transaction to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('transactions')
          .add(transaction.toMap());

      // Clear form
      _amountController.clear();
      _recipientController.clear();
      _noteController.clear();
      _categoryController.clear();

      // Reload balance
      await _loadBalance();

      setState(() {
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction added successfully!'),
            backgroundColor: kLightSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Failed to add transaction'),
            backgroundColor: kLightError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Balance Display Section
          _buildBalanceSection(scheme),
          
          SizedBox(height: 24.h),
          
          // Transaction Form Section
          _buildTransactionForm(scheme),
        ],
      ),
    );
  }

  /// Build the balance display section
  Widget _buildBalanceSection(ColorScheme scheme) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: scheme.brightness == Brightness.light
              ? [kLightGradientTop.withOpacity(0.2), kLightGradientBottom.withOpacity(0.2)]
              : [kDarkGradientTop.withOpacity(0.3), kDarkGradientBottom.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Balance',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: scheme.onSurface.withOpacity(0.65),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              _isCalculatingBalance
                  ? _buildBalanceShimmer(scheme)
                  : Text(
                      '₹ ${_currentBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: scheme.primary),
            onPressed: _isCalculatingBalance ? null : _loadBalance,
          ),
        ],
      ),
    );
  }

  /// Build the transaction form section
  Widget _buildTransactionForm(ColorScheme scheme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add New Transaction',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Amount Field
          _buildTextField(
            controller: _amountController,
            label: 'Amount',
            hint: 'Enter amount',
            prefixIcon: Icons.currency_rupee,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter amount';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Please enter a valid amount';
              }
              if (widget.transactionType == 'send' && amount > _currentBalance) {
                return 'Insufficient balance';
              }
              return null;
            },
            scheme: scheme,
          ),
          
          SizedBox(height: 12.h),
          
          // Recipient Field
          _buildTextField(
            controller: _recipientController,
            label: widget.transactionType == 'send' ? 'Recipient' : 'Sender',
            hint: 'Enter name or ID',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter recipient';
              }
              return null;
            },
            scheme: scheme,
          ),
          
          SizedBox(height: 12.h),
          
          // Category Field
          _buildTextField(
            controller: _categoryController,
            label: 'Category (Optional)',
            hint: 'e.g., Food, Transport, Bills',
            prefixIcon: Icons.category_outlined,
            scheme: scheme,
          ),
          
          SizedBox(height: 12.h),
          
          // Note Field
          _buildTextField(
            controller: _noteController,
            label: 'Note (Optional)',
            hint: 'Add a note',
            prefixIcon: Icons.note_outlined,
            maxLines: 2,
            scheme: scheme,
          ),
          
          SizedBox(height: 24.h),
          
          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _addTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.transactionType == 'send' 
                    ? scheme.primary 
                    : scheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20.h,
                      width: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.transactionType == 'send' 
                              ? Icons.north_east 
                              : Icons.south_west,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          widget.transactionType == 'send' 
                              ? 'Send Money' 
                              : 'Receive Money',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a styled text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    required ColorScheme scheme,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        fontSize: 14.sp,
        color: scheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: scheme.primary, size: 20.sp),
        labelStyle: TextStyle(
          fontSize: 14.sp,
          color: scheme.onSurface.withOpacity(0.65),
        ),
        hintStyle: TextStyle(
          fontSize: 14.sp,
          color: scheme.onSurface.withOpacity(0.4),
        ),
        filled: true,
        fillColor: scheme.brightness == Brightness.light
            ? kLightBackground
            : kDarkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: scheme.brightness == Brightness.light
                ? kLightBorder
                : kDarkBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: scheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: scheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: scheme.error,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 14.h,
        ),
      ),
    );
  }

  /// Build a shimmer effect for loading balance
  Widget _buildBalanceShimmer(ColorScheme scheme) {
    return Container(
      width: 150.w,
      height: 32.h,
      decoration: BoxDecoration(
        color: scheme.onSurface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }
}
