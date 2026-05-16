import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Pastel Palette (matches all other screens) ────────────────────────────────
class _AppColors {
  static const pastelBlue     = Color(0xFFAEC6E8);
  static const pastelOrange   = Color(0xFFFFCBA4);
  static const deepBlue       = Color(0xFF3A5A8A);
  static const deepOrange     = Color(0xFFD4845A);
  static const appBarGlass    = Color(0x883A5A8A);
  static const processing     = Color(0xFFD4845A);
  static const shipped        = Color(0xFF5A8AB0);
  static const delivered      = Color(0xFF5A8A6A);
  static const outOfStock     = Color(0xFFCC6666);
}

const _kBgGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.0, 0.40, 0.75, 1.0],
  colors: [
    Color(0xFFDCEAF7),
    Color(0xFFEAD5F0),
    Color(0xFFFFE5CC),
    Color(0xFFFFD6B0),
  ],
);

// ── Add Customer Order Screen ─────────────────────────────────────────────────
class AddCustomerOrderScreen extends StatefulWidget {
  const AddCustomerOrderScreen({super.key});

  @override
  State<AddCustomerOrderScreen> createState() =>
      _AddCustomerOrderScreenState();
}

class _AddCustomerOrderScreenState extends State<AddCustomerOrderScreen> {
  final _formKey          = GlobalKey<FormState>();
  final _customerNameCtrl = TextEditingController();
  final _addressCtrl      = TextEditingController();
  final _phoneCtrl        = TextEditingController();
  final _productCtrl      = TextEditingController();
  final _qtyCtrl          = TextEditingController();
  String _orderStatus     = 'Processing';
  bool   _isSaving        = false;
  DateTime _selectedDate   = DateTime.now(); // Added this

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _productCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  // Added this function for date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _AppColors.deepBlue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('customer_orders').add({
        'customerName':    _customerNameCtrl.text.trim(),
        'customerAddress': _addressCtrl.text.trim(),
        'phoneNumber':     _phoneCtrl.text.trim(),
        'productName':     _productCtrl.text.trim(),
        'orderQuantity':   int.tryParse(_qtyCtrl.text.trim()) ?? 0,
        'orderStatus':     _orderStatus,
        'dateCreated':     Timestamp.fromDate(_selectedDate), // Changed to use selected date
        'createdAt':       FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Order added successfully!'),
              ],
            ),
            backgroundColor: _AppColors.deepBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: _AppColors.outOfStock,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format the selected date
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: _GlassAppBar(),
      body: Container(
        decoration: const BoxDecoration(gradient: _kBgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Date Picker (now interactive) ──────────────────────────────────
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: _GlassInfoChip(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date Created',
                      value: dateStr,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Section: Customer Info ─────────────────────────────
                  _SectionLabel(
                      icon: Icons.person_outline, label: 'Customer Info'),
                  const SizedBox(height: 10),
                  _GlassFormField(
                    ctrl: _customerNameCtrl,
                    label: 'Customer Name',
                    icon: Icons.person_outline,
                    validator: _required('Customer Name'),
                  ),
                  const SizedBox(height: 10),
                  _GlassFormField(
                    ctrl: _addressCtrl,
                    label: 'Customer Address',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                    validator: _required('Customer Address'),
                  ),
                  const SizedBox(height: 10),
                  _GlassFormField(
                    ctrl: _phoneCtrl,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: _required('Phone Number'),
                  ),

                  const SizedBox(height: 20),

                  // ── Section: Order Details ─────────────────────────────
                  _SectionLabel(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Order Details'),
                  const SizedBox(height: 10),
                  _GlassFormField(
                    ctrl: _productCtrl,
                    label: 'Product Name',
                    icon: Icons.inventory_2_outlined,
                    validator: _required('Product Name'),
                  ),
                  const SizedBox(height: 10),
                  _GlassFormField(
                    ctrl: _qtyCtrl,
                    label: 'Order Quantity',
                    icon: Icons.numbers_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Order Quantity is required';
                      if (int.tryParse(v.trim()) == null)
                        return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // ── Status Dropdown ────────────────────────────────────
                  _GlassStatusDropdown(
                    value: _orderStatus,
                    onChanged: (val) =>
                        setState(() => _orderStatus = val ?? _orderStatus),
                  ),

                  const SizedBox(height: 28),

                  // ── Save Button ────────────────────────────────────────
                  _GlassSaveButton(
                    isSaving: _isSaving,
                    onTap: _isSaving ? null : _saveOrder,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? Function(String?) _required(String field) =>
      (v) => (v == null || v.trim().isEmpty) ? '$field is required' : null;
}

// ── Glass App Bar ─────────────────────────────────────────────────────────────
class _GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AppBar(
          backgroundColor: _AppColors.appBarGlass,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Add Customer Order',
            style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
          ),
        ),
      ),
    );
  }
}

// ── Glass Info Chip (Date display - now tappable) ────────────────────────────────────────────
class _GlassInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _GlassInfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.70)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _AppColors.pastelBlue.withOpacity(0.50),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.70)),
                    ),
                    child: Icon(icon,
                        size: 15, color: _AppColors.deepBlue),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: _AppColors.deepBlue.withOpacity(0.60),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _AppColors.deepBlue,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_drop_down, color: _AppColors.deepBlue.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.45),
                borderRadius: BorderRadius.circular(7),
                border:
                    Border.all(color: Colors.white.withOpacity(0.70)),
              ),
              child: Icon(icon, size: 14, color: _AppColors.deepBlue),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _AppColors.deepBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(color: Colors.white.withOpacity(0.60)),
        ),
      ],
    );
  }
}

// ── Glass Form Field ──────────────────────────────────────────────────────────
class _GlassFormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _GlassFormField({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
              color: _AppColors.deepBlue,
              fontSize: 14,
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
                color: _AppColors.deepBlue.withOpacity(0.65),
                fontSize: 13),
            filled: true,
            fillColor: Colors.white.withOpacity(0.55),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.65)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: _AppColors.pastelBlue.withOpacity(0.55)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: _AppColors.deepBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: _AppColors.outOfStock, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: _AppColors.outOfStock, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Glass Status Dropdown ─────────────────────────────────────────────────────
class _GlassStatusDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _GlassStatusDropdown({
    required this.value,
    required this.onChanged,
  });

  static const _items = ['Processing', 'Shipped', 'Delivered'];

  Color _colorFor(String s) {
    switch (s) {
      case 'Shipped':   return _AppColors.shipped;
      case 'Delivered': return _AppColors.delivered;
      default:          return _AppColors.processing;
    }
  }

  IconData _iconFor(String s) {
    switch (s) {
      case 'Shipped':   return Icons.local_shipping_outlined;
      case 'Delivered': return Icons.check_circle_outline;
      default:          return Icons.hourglass_empty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: DropdownButtonFormField<String>(
          value: value,
          dropdownColor: const Color(0xFFEEF4FF),
          style: TextStyle(color: _AppColors.deepBlue, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Order Status',
            labelStyle: TextStyle(
                color: _AppColors.deepBlue.withOpacity(0.65),
                fontSize: 13),
            filled: true,
            fillColor: Colors.white.withOpacity(0.55),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.65)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: _AppColors.pastelBlue.withOpacity(0.55)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: _AppColors.deepBlue, width: 1.5),
            ),
          ),
          items: _items.map((s) {
            return DropdownMenuItem(
              value: s,
              child: Row(
                children: [
                  Icon(_iconFor(s), color: _colorFor(s), size: 16),
                  const SizedBox(width: 8),
                  Text(s,
                      style: TextStyle(
                          color: _colorFor(s),
                          fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Glass Save Button ─────────────────────────────────────────────────────────
class _GlassSaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback? onTap;

  const _GlassSaveButton({required this.isSaving, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: isSaving
                  ? _AppColors.deepBlue.withOpacity(0.55)
                  : _AppColors.deepBlue.withOpacity(0.88),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.50)),
            ),
            child: Center(
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.save_outlined,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Save Order',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}