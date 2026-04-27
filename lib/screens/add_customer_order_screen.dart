import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddCustomerOrderScreen extends StatefulWidget {
  const AddCustomerOrderScreen({super.key});

  @override
  State<AddCustomerOrderScreen> createState() => _AddCustomerOrderScreenState();
}

class _AddCustomerOrderScreenState extends State<AddCustomerOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameCtrl = TextEditingController();
  final _customerAddressCtrl = TextEditingController();
  final _phoneNumberCtrl = TextEditingController();
  final _productNameCtrl = TextEditingController();
  final _orderQuantityCtrl = TextEditingController();
  String _orderStatus = 'Processing';
  bool _isSaving = false;

  final List<String> _statusOptions = ['Processing', 'Shipped', 'Delivered'];

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerAddressCtrl.dispose();
    _phoneNumberCtrl.dispose();
    _productNameCtrl.dispose();
    _orderQuantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('customer_orders').add({
        'customerName': _customerNameCtrl.text.trim(),
        'customerAddress': _customerAddressCtrl.text.trim(),
        'phoneNumber': _phoneNumberCtrl.text.trim(),
        'productName': _productNameCtrl.text.trim(),
        'orderQuantity': int.tryParse(_orderQuantityCtrl.text.trim()) ?? 0,
        'orderStatus': _orderStatus,
        'dateCreated': FieldValue.serverTimestamp(),
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
            backgroundColor: const Color(0xFF1B1B4E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1B1B4E), width: 2),
          ),
        ),
        validator: validator ??
            (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Customer Order'),
        backgroundColor: const Color(0xFF1B1B4E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Created display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B4E).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1B1B4E).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Color(0xFF1B1B4E)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date Created',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B1B4E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              _buildField(_customerNameCtrl, 'Customer Name'),
              _buildField(_customerAddressCtrl, 'Customer Address', maxLines: 2),
              _buildField(
                _phoneNumberCtrl,
                'Phone Number',
                keyboardType: TextInputType.phone,
              ),
              _buildField(_productNameCtrl, 'Product Name'),
              _buildField(
                _orderQuantityCtrl,
                'Order Quantity',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Order Quantity is required';
                  if (int.tryParse(v.trim()) == null) return 'Enter a valid number';
                  return null;
                },
              ),

              // Order Status dropdown
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: DropdownButtonFormField<String>(
                  value: _orderStatus,
                  decoration: InputDecoration(
                    labelText: 'Order Status',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF1B1B4E), width: 2),
                    ),
                  ),
                  items: _statusOptions.map((status) {
                    Color chipColor;
                    IconData chipIcon;
                    if (status == 'Processing') {
                      chipColor = Colors.orange;
                      chipIcon = Icons.hourglass_empty;
                    } else if (status == 'Shipped') {
                      chipColor = Colors.blue;
                      chipIcon = Icons.local_shipping_outlined;
                    } else {
                      chipColor = Colors.green;
                      chipIcon = Icons.check_circle_outline;
                    }
                    return DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Icon(chipIcon, color: chipColor, size: 18),
                          const SizedBox(width: 8),
                          Text(status),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _orderStatus = val!),
                ),
              ),

              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveOrder,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Save Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B1B4E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}