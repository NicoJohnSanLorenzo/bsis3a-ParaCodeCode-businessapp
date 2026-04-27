import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class CreateCheckinScreen extends StatefulWidget {
  const CreateCheckinScreen({super.key});

  @override
  State<CreateCheckinScreen> createState() => _CreateCheckinScreenState();
}

class _CreateCheckinScreenState extends State<CreateCheckinScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _productNameController = TextEditingController();
  final _noteController = TextEditingController();
  final _createdByController = TextEditingController();
  final _supplierNameController = TextEditingController();

  String? _stockStatus;
  final List<String> _stockStatusOptions = ['In-stock', 'Low stock', 'Out-of-stock'];

  double? _lat;
  double? _lng;
  XFile? _selectedImage;
  bool _isLoading = false;
  bool _isFetchingLocation = false;
  bool _isPickingPhoto = false;
  bool _showSuccess = false;

  late AnimationController _successAnimController;
  late Animation<double> _successScaleAnim;
  late Animation<double> _successFadeAnim;

  @override
  void initState() {
    super.initState();
    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScaleAnim = CurvedAnimation(
      parent: _successAnimController,
      curve: Curves.elasticOut,
    );
    _successFadeAnim = CurvedAnimation(
      parent: _successAnimController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _noteController.dispose();
    _createdByController.dispose();
    _supplierNameController.dispose();
    _successAnimController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Location permission denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Location permission permanently denied.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });
      _showSnack('Location fetched!');
    } catch (e) {
      _showSnack('Failed to get location: $e');
    } finally {
      setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
    if (picked == null) return;

    setState(() {
      _selectedImage = picked;
      _isPickingPhoto = false;
    });
    _showSnack('Photo selected!');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final docRef = FirebaseFirestore.instance.collection('checkin_logs').doc();
      final docId = docRef.id;

      await docRef.set({
        'id': docId,
        'productName': _productNameController.text.trim(),
        'note': _noteController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'photoBase64': base64Image,
        'lat': _lat,
        'lng': _lng,
        'createdBy': _createdByController.text.trim(),
        'stockStatus': _stockStatus ?? 'In-stock',
        'supplierName': _supplierNameController.text.trim(),
      });

      setState(() {
        _isLoading = false;
        _showSuccess = true;
      });
      _successAnimController.forward();
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Failed to save: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Add Inventory Order'),
            backgroundColor: const Color(0xFF1B1B4E),
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildField(
                    controller: _productNameController,
                    label: 'Product Name',
                    icon: Icons.inventory_2_outlined,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _noteController,
                    label: 'Note',
                    icon: Icons.notes,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _createdByController,
                    label: 'Created By (name / nickname / device)',
                    icon: Icons.person,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Stock Status Dropdown
                  DropdownButtonFormField<String>(
                    value: _stockStatus,
                    decoration: InputDecoration(
                      labelText: 'Stock Status',
                      prefixIcon: const Icon(Icons.bar_chart, color: Color(0xFF1B1B4E)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF1B1B4E), width: 2),
                      ),
                    ),
                    hint: const Text('Select Stock Status'),
                    items: _stockStatusOptions.map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Row(
                          children: [
                            Icon(
                              _stockStatusIcon(status),
                              size: 18,
                              color: _stockStatusColor(status),
                            ),
                            const SizedBox(width: 8),
                            Text(status),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _stockStatus = val),
                    validator: (v) => v == null ? 'Please select a stock status' : null,
                  ),

                  const SizedBox(height: 14),
                  _buildField(
                    controller: _supplierNameController,
                    label: 'Supplier Name',
                    icon: Icons.local_shipping_outlined,
                  ),
                  const SizedBox(height: 20),

                  // GPS Section
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GPS Location',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            _lat != null && _lng != null
                                ? 'Lat: ${_lat!.toStringAsFixed(6)},  Lng: ${_lng!.toStringAsFixed(6)}'
                                : 'Not yet fetched',
                            key: ValueKey(_lat),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isFetchingLocation ? null : _fetchLocation,
                            icon: _isFetchingLocation
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.my_location),
                            label: Text(_isFetchingLocation ? 'Fetching...' : 'Get Location'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Photo Section
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Photo',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  key: ValueKey(_selectedImage!.path),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_selectedImage!.path),
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const SizedBox.shrink(key: ValueKey('no_image')),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isPickingPhoto ? null : _pickPhoto,
                            icon: _isPickingPhoto
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.camera_alt_outlined),
                            label: Text(_isPickingPhoto ? 'Opening camera...' : 'Take / Upload Photo'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B1B4E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _isLoading
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              key: ValueKey('label'),
                              'Save Inventory Order',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),

        // Full-screen success overlay
        if (_showSuccess)
          FadeTransition(
            opacity: _successFadeAnim,
            child: Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: ScaleTransition(
                scale: _successScaleAnim,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF1B1B4E), size: 72),
                      SizedBox(height: 12),
                      Text(
                        'Saved!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B1B4E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  IconData _stockStatusIcon(String status) {
    switch (status) {
      case 'In-stock':
        return Icons.check_circle_outline;
      case 'Low stock':
        return Icons.warning_amber_outlined;
      case 'Out-of-stock':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Color _stockStatusColor(String status) {
    switch (status) {
      case 'In-stock':
        return Colors.green;
      case 'Low stock':
        return Colors.orange;
      case 'Out-of-stock':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1B1B4E)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1B1B4E), width: 2),
        ),
      ),
    );
  }
}
