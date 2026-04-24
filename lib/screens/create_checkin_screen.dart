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

class _CreateCheckinScreenState extends State<CreateCheckinScreen> {
  final _formKey = GlobalKey<FormState>();

  final _businessNameController = TextEditingController();
  final _noteController = TextEditingController();
  final _createdByController = TextEditingController();
  final _stockIssueController = TextEditingController();
  final _supplierNameController = TextEditingController();

  double? _lat;
  double? _lng;
  XFile? _selectedImage;
  bool _isLoading = false;
  bool _isFetchingLocation = false;
  bool _isPickingPhoto = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _noteController.dispose();
    _createdByController.dispose();
    _stockIssueController.dispose();
    _supplierNameController.dispose();
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
        'businessName': _businessNameController.text.trim(),
        'note': _noteController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'photoBase64': base64Image,
        'lat': _lat,
        'lng': _lng,
        'createdBy': _createdByController.text.trim(),
        'stockIssue': _stockIssueController.text.trim(),
        'supplierName': _supplierNameController.text.trim(),
      });

      _showSnack('Check-in log saved!');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack('Failed to save: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Check-In Log'),
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
                controller: _businessNameController,
                label: 'Business Name',
                icon: Icons.business,
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
              _buildField(
                controller: _stockIssueController,
                label: 'Stock Issue',
                icon: Icons.warning_amber_outlined,
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
                    Text(
                      _lat != null && _lng != null
                          ? 'Lat: ${_lat!.toStringAsFixed(6)},  Lng: ${_lng!.toStringAsFixed(6)}'
                          : 'Not yet fetched',
                      style: const TextStyle(fontSize: 14),
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
                    if (_selectedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedImage!.path),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
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
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Check-In Log', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
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