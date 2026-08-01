import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/glass_container.dart';

class CreateBannerScreen extends StatefulWidget {
  const CreateBannerScreen({super.key});

  @override
  State<CreateBannerScreen> createState() => _CreateBannerScreenState();
}

class _CreateBannerScreenState extends State<CreateBannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _linkController = TextEditingController();
  
  String _actionType = 'Open Category';
  
  final List<String> _actionTypes = [
    'Open Product', 'Open Category', 'Open Shop', 'Open Offer', 'External Link'
  ];

  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final file = File(image.path);
      final fileSize = file.lengthSync();
      
      // 2MB size limit
      if (fileSize > 2 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image is too large. Max size is 2MB.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      // Check aspect ratio
      try {
        final bytes = await file.readAsBytes();
        final decodedImage = await decodeImageFromList(bytes);
        final aspectRatio = decodedImage.width / decodedImage.height;
        
        // App banner is ~160px height and full width (~380px). Ideal aspect ratio is ~2.3
        // We restrict it to be between 1.8 and 2.8 to prevent squared or highly vertical images
        if (aspectRatio < 1.8 || aspectRatio > 2.8) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid aspect ratio. Please upload a wide image (e.g. 1200 x 500 pixels).'), 
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      } catch (e) {
        // If it fails to decode, we can either block it or allow it. Let's block it for safety.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid image format.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      setState(() {
        _imageFile = file;
      });
    }
  }

  Future<void> _submitBanner() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a banner image')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Upload image
      final fileExt = _imageFile!.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '${user.id}/$fileName';
      
      await Supabase.instance.client.storage
          .from('banners')
          .upload(filePath, _imageFile!);
          
      final imageUrl = Supabase.instance.client.storage
          .from('banners')
          .getPublicUrl(filePath);

      // Insert banner record
      await Supabase.instance.client.from('banners').insert({
        'merchant_id': user.id,
        'title': 'Image Banner',
        'subtitle': '',
        'image_url': imageUrl,
        'banner_type': 'Custom',
        'action_type': _actionType,
        'city': null,
        'start_date': null,
        'end_date': null,
        'status': 'Approved',
        'external_link': _actionType == 'External Link' ? _linkController.text.trim() : null,
        'category_id': _actionType == 'Open Category' ? _linkController.text.trim() : null,
        'product_id': _actionType == 'Open Product' ? _linkController.text.trim() : null,
        'shop_id': _actionType == 'Open Shop' ? _linkController.text.trim() : null,
        'offer_id': _actionType == 'Open Offer' ? _linkController.text.trim() : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner created successfully!'), backgroundColor: Colors.green),
        );
        // Reset form
        _formKey.currentState!.reset();
        setState(() {
          _linkController.clear();
          _imageFile = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('Create Banner', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.electricBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImagePicker(),
                    const SizedBox(height: 24),
                    
                    _buildDropdown('Action Type', _actionType, _actionTypes, (v) => setState(() => _actionType = v!)),
                    const SizedBox(height: 16),
                    
                    if (_actionType != 'Open Shop') // If open shop, we can default to their own shop later, or they can enter it
                      _buildTextField(_linkController, 'Target ID / Link (for $_actionType)', Icons.link, required: true),
                    if (_actionType != 'Open Shop')
                      const SizedBox(height: 32),
                    
                    ElevatedButton(
                      onPressed: _submitBanner,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Create Banner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_rounded, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text('Tap to upload banner image', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool required = false}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.electricBlue),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.electricBlue)),
      ),
      validator: required ? (v) => v == null || v.isEmpty ? 'Required field' : null : null,
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: AppColors.textPrimary)))).toList(),
      onChanged: onChanged,
      dropdownColor: Colors.white,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.electricBlue)),
      ),
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }
}
