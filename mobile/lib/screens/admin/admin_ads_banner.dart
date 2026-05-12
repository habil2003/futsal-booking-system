import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AdsBannerScreen extends StatefulWidget {
  const AdsBannerScreen({super.key});

  @override
  State<AdsBannerScreen> createState() => _AdsBannerScreenState();
}

String _formatDate(String? dateString) {
  if (dateString == null) return 'Unknown date';
  try {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year}';
  } catch (e) {
    return 'Invalid date';
  }
}

class _AdsBannerScreenState extends State<AdsBannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _buttonTextController = TextEditingController();
  final _buttonLinkController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingAds = false;
  XFile? _selectedImage;
  String? _previewImageUrl;
  List<Map<String, dynamic>> _ads = [];
  int? _editingAdId;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _buttonTextController.dispose();
    _buttonLinkController.dispose();
    super.dispose();
  }

  Future<void> _loadAds() async {
    setState(() => _isLoadingAds = true);
    try {
      final response = await ApiService.getList('ads');
      setState(() {
        _ads = response.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to load ads: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoadingAds = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _selectedImage = image;
        if (kIsWeb) _previewImageUrl = image.path;
      });
    }
  }

  Future<void> _submitAd() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null && _editingAdId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select an image'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final urls = await ApiService.uploadImages([_selectedImage!]);
        if (urls.isEmpty) throw 'Image upload failed';
        imageUrl = urls.first;
      }

      final adData = {
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'buttonText': _buttonTextController.text.trim(),
        'buttonLink': _buttonLinkController.text.trim(),
        if (imageUrl != null) 'imageUrl': imageUrl,
        'isActive': true,
      };

      final response = _editingAdId == null
          ? await ApiService.createAd(adData)
          : await ApiService.put('ads/${_editingAdId}', adData);

      if (!mounted) return;

      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingAdId == null ? 'Ad created' : 'Ad updated'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
        _loadAds();
      } else {
        throw response['message'] ?? 'Operation failed';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _editAd(Map<String, dynamic> ad) {
    setState(() {
      _editingAdId = ad['id'];
      _titleController.text = ad['title'] ?? '';
      _subtitleController.text = ad['subtitle'] ?? '';
      _buttonTextController.text = ad['buttonText'] ?? '';
      _buttonLinkController.text = ad['buttonLink'] ?? '';
      _previewImageUrl = ad['imageUrl'];
      _selectedImage = null;
    });
  }

  Future<void> _deleteAd(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Ad'),
        content: const Text('Are you sure you want to delete this ad?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.delete('ads/$id');
      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Ad deleted'), backgroundColor: Colors.green),
        );
        _loadAds();
        if (_editingAdId == id) _clearForm();
      } else {
        throw response['message'] ?? 'Delete failed';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleActive(int id, bool currentStatus) async {
    try {
      final response =
          await ApiService.patch('ads/$id', {'isActive': !currentStatus});
      if (response['status'] == 'success') {
        _loadAds();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _clearForm() {
    _titleController.clear();
    _subtitleController.clear();
    _buttonTextController.clear();
    _buttonLinkController.clear();
    setState(() {
      _editingAdId = null;
      _selectedImage = null;
      _previewImageUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Advertisements'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_editingAdId != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearForm,
              tooltip: 'Cancel editing',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create/Edit Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editingAdId == null ? 'Create New Ad' : 'Edit Ad',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildImagePicker(),
                  const SizedBox(height: 16),
                  _buildTextField(
                      _titleController, 'Title', 'e.g., Summer Special'),
                  const SizedBox(height: 16),
                  _buildTextField(_subtitleController, 'Subtitle',
                      'e.g., 30% OFF on all courts'),
                  const SizedBox(height: 16),
                  _buildTextField(
                      _buttonTextController, 'Button Text', 'e.g., Book Now'),
                  const SizedBox(height: 16),
                  _buildTextField(_buttonLinkController, 'Button Link (URL)',
                      'https://example.com', TextInputType.url),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitAd,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(_editingAdId == null
                                  ? 'Create Ad'
                                  : 'Update Ad'),
                        ),
                      ),
                      if (_editingAdId != null) ...[
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: _clearForm,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 16),

            // Heading for existing ads
            const Row(
              children: [
                Icon(Icons.campaign, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Added Advertisements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Existing Ads List
            _isLoadingAds
                ? const Center(child: CircularProgressIndicator())
                : _ads.isEmpty
                    ? const Center(child: Text('No ads created yet'))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _ads.length,
                        itemBuilder: (context, index) {
                          final ad = _ads[index];
                          return _buildAdTile(ad);
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: _previewImageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: kIsWeb
                    ? Image.network(_previewImageUrl!, fit: BoxFit.cover)
                    : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 48, color: Colors.grey.shade600),
                  const SizedBox(height: 8),
                  Text('Tap to select image',
                      style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text('Recommended: 1200x600 px',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, String hint,
      [TextInputType? keyboardType]) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: (value) =>
          value?.isEmpty == true ? '$label is required' : null,
    );
  }

  Widget _buildAdTile(Map<String, dynamic> ad) {
    final bool isActive = ad['isActive'] ?? true;
    final String createdAt = _formatDate(ad['createdAt']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                ad['imageUrl'] ?? '',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad['title'] ?? 'Untitled',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ad['subtitle'] ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Created: $createdAt',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isActive ? Icons.visibility : Icons.visibility_off,
                    color: isActive ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  onPressed: () => _toggleActive(ad['id'], isActive),
                  tooltip: isActive ? 'Active' : 'Inactive',
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () => _editAd(ad),
                  tooltip: 'Edit',
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _deleteAd(ad['id']),
                  tooltip: 'Delete',
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// Helper to format date
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
