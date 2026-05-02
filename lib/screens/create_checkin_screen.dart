import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Your color palette
class AppColors {
  static const pastelBlue     = Color(0xFFAEC6E8);
  static const pastelOrange   = Color(0xFFFFCBA4);
  static const pastelPeach    = Color(0xFFFFE5CC);
  static const pastelLavender = Color(0xFFEAD5F0);
  static const deepBlue       = Color(0xFF3A5A8A);
  static const deepOrange     = Color(0xFFD4845A);
  static const processing     = Color(0xFFD4845A);
  static const shipped        = Color(0xFF5A8AB0);
  static const delivered      = Color(0xFF5A8A6A);
  static const lowStock       = Color(0xFFCB9A50);
  static const outOfStock     = Color(0xFFCC6666);
}

const kBgGradient = LinearGradient(
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
  
  // New controllers for the proof label feature
  final _groupNameController = TextEditingController();
  final _businessTypeController = TextEditingController();

  String? _stockStatus;
  final List<String> _stockStatusOptions = ['In-stock', 'Low stock', 'Out-of-stock'];

  double? _lat;
  double? _lng;
  XFile? _selectedImage;
  bool _isLoading = false;
  bool _isFetchingLocation = false;
  bool _isPickingPhoto = false;
  bool _showSuccess = false;
  String _proofLabel = '';

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
    
    // Add listeners to update proof label when group name or business type changes
    _groupNameController.addListener(_updateProofLabel);
    _businessTypeController.addListener(_updateProofLabel);
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _noteController.dispose();
    _createdByController.dispose();
    _supplierNameController.dispose();
    _groupNameController.dispose();
    _businessTypeController.dispose();
    _successAnimController.dispose();
    super.dispose();
  }

  void _updateProofLabel() {
    final groupName = _groupNameController.text.trim();
    final businessType = _businessTypeController.text.trim();
    
    if (groupName.isNotEmpty && businessType.isNotEmpty) {
      final now = DateTime.now();
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      setState(() {
        _proofLabel = '$groupName-$businessType-$month$day';
      });
    } else {
      setState(() {
        _proofLabel = '';
      });
    }
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

  Future<void> _showPhotoSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Choose Photo Source',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.deepBlue),
                ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.camera_alt, size: 28, color: AppColors.deepBlue),
                title: const Text('Take a Photo'),
                subtitle: const Text('Use camera to take a new photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, size: 28, color: AppColors.deepBlue),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select from saved photos'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _isPickingPhoto = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 25,
      );
      
      if (picked != null) {
        setState(() {
          _selectedImage = picked;
        });
        _showSnack('Photo selected successfully!');
      } else {
        _showSnack('No photo selected');
      }
    } catch (e) {
      _showSnack('Failed to pick photo: $e');
    } finally {
      setState(() => _isPickingPhoto = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_proofLabel.isEmpty) {
      _showSnack('Please enter Group Name and Business Type to generate Proof Label');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> data = {
        'proofLabel': _proofLabel,
        'productName': _productNameController.text.trim(),
        'note': _noteController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _createdByController.text.trim(),
        'stockStatus': _stockStatus ?? 'In-stock',
        'supplierName': _supplierNameController.text.trim(),
        'groupName': _groupNameController.text.trim(),
        'businessType': _businessTypeController.text.trim(),
      };

      if (_lat != null && _lng != null) {
        data['lat'] = _lat;
        data['lng'] = _lng;
      }

      if (_selectedImage != null) {
        data['hasPhoto'] = true;
        data['photoFileName'] = _selectedImage!.name;
      }

      final docRef = FirebaseFirestore.instance.collection('checkin_logs').doc();
      final docId = docRef.id;
      data['id'] = docId;

      await docRef.set(data);
      
      print('SAVED WITH PROOF LABEL: ${_proofLabel}'); // Debug print

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
      print('Error details: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Add Inventory Order',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
        backgroundColor: AppColors.deepBlue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: kBgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Proof Label Section ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.pastelBlue.withOpacity(0.3),
                      border: Border.all(color: AppColors.deepBlue),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified_outlined, color: AppColors.deepBlue, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Proof Label (Required)',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildField(
                          controller: _groupNameController,
                          label: 'Group Name',
                          hint: 'e.g., GetGetAw, Zape-R-Disapir, etc.',
                        ),
                        const SizedBox(height: 8),
                        _buildField(
                          controller: _businessTypeController,
                          label: 'Business Type',
                          hint: 'e.g., Hotel, Clinic, Retail',
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.deepBlue.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.qr_code, size: 20, color: AppColors.deepBlue),
                              const SizedBox(width: 8),
                              const Text(
                                'Proof: ',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Expanded(
                                child: Text(
                                  _proofLabel.isEmpty ? 'Enter Group Name & Business Type' : _proofLabel,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _proofLabel.isEmpty ? AppColors.outOfStock : AppColors.deepBlue,
                                    fontWeight: _proofLabel.isEmpty ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

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
                    label: 'Created By',
                    icon: Icons.person,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Stock Status Dropdown
                  DropdownButtonFormField<String>(
                    value: _stockStatus,
                    decoration: InputDecoration(
                      labelText: 'Stock Status',
                      labelStyle: TextStyle(color: AppColors.deepBlue.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.bar_chart, color: AppColors.deepBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.pastelBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.deepBlue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
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
                      color: Colors.white.withOpacity(0.9),
                      border: Border.all(color: AppColors.pastelBlue),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, color: AppColors.deepBlue, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'GPS Location',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            _lat != null && _lng != null
                                ? 'Lat: ${_lat!.toStringAsFixed(6)},  Lng: ${_lng!.toStringAsFixed(6)}'
                                : 'Not yet fetched',
                            key: ValueKey(_lat),
                            style: TextStyle(fontSize: 13, color: AppColors.deepBlue.withOpacity(0.7)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isFetchingLocation ? null : _fetchLocation,
                            icon: _isFetchingLocation
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : Icon(Icons.my_location, color: AppColors.deepBlue),
                            label: Text(_isFetchingLocation ? 'Fetching...' : 'Get Location'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.deepBlue,
                              side: BorderSide(color: AppColors.pastelBlue),
                            ),
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
                      color: Colors.white.withOpacity(0.9),
                      border: Border.all(color: AppColors.pastelBlue),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.photo_camera_outlined, color: AppColors.deepBlue, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Photo',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          child: _selectedImage != null
                              ? Column(
                                  key: ValueKey(_selectedImage!.path),
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(_selectedImage!.path),
                                        height: 160,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _selectedImage = null;
                                        });
                                        _showSnack('Photo removed');
                                      },
                                      icon: const Icon(Icons.delete_outline, size: 16),
                                      label: const Text('Remove Photo'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.outOfStock,
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(key: ValueKey('no_image')),
                        ),
                        
                        const SizedBox(height: 10),
                        
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isPickingPhoto ? null : () => _showPhotoSourceDialog(),
                                icon: _isPickingPhoto
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : Icon(Icons.add_photo_alternate_outlined, color: AppColors.deepBlue),
                                label: Text(_isPickingPhoto ? 'Loading...' : 'Add Photo'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.deepBlue,
                                  side: BorderSide(color: AppColors.pastelBlue),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          'You can take a new photo or choose from gallery',
                          style: TextStyle(fontSize: 10, color: AppColors.deepBlue.withOpacity(0.5)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Save Inventory Order',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
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
        return AppColors.delivered;
      case 'Low stock':
        return AppColors.lowStock;
      case 'Out-of-stock':
        return AppColors.outOfStock;
      default:
        return AppColors.deepBlue;
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: AppColors.deepBlue),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.deepBlue.withOpacity(0.5), fontSize: 12),
        labelStyle: TextStyle(color: AppColors.deepBlue.withOpacity(0.7)),
        prefixIcon: icon != null ? Icon(icon, color: AppColors.deepBlue) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.pastelBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.deepBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
      ),
    );
  }
}