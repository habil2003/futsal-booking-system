import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/court_provider.dart';
import '../../models/court.dart';

class CourtManagementScreen extends StatefulWidget {
  final int futsalId;
  final String futsalName;

  const CourtManagementScreen({
    super.key,
    required this.futsalId,
    required this.futsalName,
  });

  @override
  State<CourtManagementScreen> createState() => _CourtManagementScreenState();
}

class _CourtManagementScreenState extends State<CourtManagementScreen> {
  final TextEditingController _courtNumberController = TextEditingController();
  final TextEditingController _basePriceController = TextEditingController();
  final TextEditingController _peakPriceController = TextEditingController();

  String _selectedCourtType = 'indoor';
  List<String> _selectedAmenities = [];

  final List<String> _courtTypes = ['indoor', 'outdoor'];
  final List<String> _availableAmenities = [
    'Lights',
    'Roof',
    'Changing Room',
    'Parking',
    'Drinking Water',
    'Seating',
    'Floodlights',
    'Synthetic Turf',
  ];

  @override
  void initState() {
    super.initState();
    _loadCourts();
  }

  Future<void> _loadCourts() async {
    debugPrint(
        '📍 CourtManagement: Loading courts for futsal ${widget.futsalId}');
    final provider = Provider.of<CourtProvider>(context, listen: false);
    await provider.loadCourts(widget.futsalId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.futsalName} - Courts'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCourts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<CourtProvider>(
        builder: (ctx, provider, _) {
          if (provider.isLoading && provider.courts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading courts...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 60, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(
                      provider.error!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadCourts,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.courts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_soccer,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No courts added yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first court',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddCourtDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Court'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary Card
              _buildSummaryCard(provider),

              // Courts List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.courts.length,
                  itemBuilder: (ctx, index) {
                    final court = provider.courts[index];
                    return _buildCourtCard(court, provider);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCourtDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Court'),
        backgroundColor: Colors.green,
        tooltip: 'Add new court',
      ),
    );
  }

  Widget _buildSummaryCard(CourtProvider provider) {
    final totalCourts = provider.courts.length;
    final activeCourts = provider.courts.where((c) => c.isActive).length;
    final maintenanceCourts =
        provider.courts.where((c) => c.isUnderMaintenance).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Court Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                label: 'Total',
                value: totalCourts.toString(),
                icon: Icons.sports_soccer,
                color: Colors.blue,
              ),
              _buildSummaryItem(
                label: 'Active',
                value: activeCourts.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              _buildSummaryItem(
                label: 'Maintenance',
                value: maintenanceCourts.toString(),
                icon: Icons.build,
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildCourtCard(Court court, CourtProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (court.isUnderMaintenance)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.build, size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Under Maintenance',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (court.maintenanceUntil != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Until ${_formatDate(court.maintenanceUntil!)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (!court.isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.block, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Court Number with Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: court.isActive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      court.courtNumber,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: court.isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Court Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Court ${court.courtNumber}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: court.courtType == 'indoor'
                                  ? Colors.blue.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              court.courtType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                color: court.courtType == 'indoor'
                                    ? Colors.blue.shade700
                                    : Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Price info
                      Row(
                        children: [
                          const Icon(Icons.currency_rupee,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 2),
                          Text(
                            'रू ${court.basePrice}/hr',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (court.peakPrice != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border:
                                    Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    size: 10,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Peak: रू ${court.peakPrice}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Amenities
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: court.amenities.map((amenity) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              amenity,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Column(
                  children: [
                    // Toggle Active/Inactive
                    IconButton(
                      icon: Icon(
                        court.isActive
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: court.isActive ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () => _toggleActive(court, provider),
                      tooltip: court.isActive ? 'Deactivate' : 'Activate',
                    ),

                    // Toggle Maintenance
                    IconButton(
                      icon: Icon(
                        Icons.build,
                        color: court.isUnderMaintenance
                            ? Colors.orange
                            : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () => _toggleMaintenance(court, provider),
                      tooltip: court.isUnderMaintenance
                          ? 'Mark Available'
                          : 'Mark Maintenance',
                    ),

                    // More options
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          child: const ListTile(
                            leading: Icon(Icons.edit, size: 18),
                            title: Text('Edit Court'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: () =>
                              _showEditCourtDialog(court.courtNumber, court),
                        ),
                        PopupMenuItem(
                          child: const ListTile(
                            leading: Icon(Icons.trending_up,
                                size: 18, color: Colors.orange),
                            title: Text('Set Peak Price'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: () => _showPeakPriceDialog(court, provider),
                        ),
                        PopupMenuItem(
                          child: const ListTile(
                            leading:
                                Icon(Icons.delete, size: 18, color: Colors.red),
                            title: Text('Delete Court',
                                style: TextStyle(color: Colors.red)),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: () => _showDeleteDialog(court, provider),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCourtDialog() {
    // Create local copies for the dialog
    TextEditingController localCourtNumberController = TextEditingController();
    TextEditingController localBasePriceController = TextEditingController();
    TextEditingController localPeakPriceController = TextEditingController();
    String localSelectedCourtType = 'indoor';
    List<String> localSelectedAmenities = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add New Court'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Court Number
                  TextField(
                    controller: localCourtNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Court Number',
                      hintText: 'e.g., 1, 2, A, B',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Court Type
                  DropdownButtonFormField(
                    value: localSelectedCourtType,
                    items: _courtTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        localSelectedCourtType = value.toString();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Court Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Base Price
                  TextField(
                    controller: localBasePriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Base Price (per hour)',
                      prefixText: 'रू ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Peak Price (Optional)
                  TextField(
                    controller: localPeakPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Peak Price (per hour) - Optional',
                      prefixText: 'रू ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Amenities Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Amenities',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableAmenities.map((amenity) {
                          final isSelected =
                              localSelectedAmenities.contains(amenity);
                          return FilterChip(
                            label: Text(amenity),
                            selected: isSelected,
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  localSelectedAmenities.add(amenity);
                                } else {
                                  localSelectedAmenities.remove(amenity);
                                }
                              });
                            },
                            backgroundColor: Colors.grey.shade100,
                            selectedColor: Colors.green.shade100,
                            checkmarkColor: Colors.green,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.green
                                  : Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.green
                                    : Colors.grey.shade300,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () => _addCourt(
                  localCourtNumberController.text,
                  localBasePriceController.text,
                  localPeakPriceController.text,
                  localSelectedCourtType,
                  localSelectedAmenities,
                  ctx,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('ADD COURT'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amenities',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableAmenities.map((amenity) {
            final isSelected = _selectedAmenities.contains(amenity);
            return FilterChip(
              label: Text(amenity),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedAmenities.add(amenity);
                  } else {
                    _selectedAmenities.remove(amenity);
                  }
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.green.shade100,
              checkmarkColor: Colors.green,
              labelStyle: TextStyle(
                color: isSelected ? Colors.green : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.green : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _addCourt(
    String courtNumber,
    String basePrice,
    String peakPrice,
    String courtType,
    List<String> amenities,
    BuildContext dialogContext,
  ) async {
    if (courtNumber.isEmpty || basePrice.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(dialogContext); // Close dialog

    final provider = Provider.of<CourtProvider>(context, listen: false);

    final courtData = {
      'futsalId': widget.futsalId,
      'courtNumber': courtNumber,
      'courtType': courtType,
      'basePrice': int.parse(basePrice),
      'peakPrice': peakPrice.isNotEmpty ? int.parse(peakPrice) : null,
      'amenities': amenities,
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final response = await provider.addCourt(courtData);

    if (mounted) Navigator.pop(context); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message']),
        backgroundColor:
            response['status'] == 'success' ? Colors.green : Colors.red,
      ),
    );

    if (response['status'] == 'success') {
      _loadCourts();
    }
  }

  void _toggleMaintenance(Court court, CourtProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final response = await provider.toggleMaintenance(
      court.id,
      !court.isUnderMaintenance,
    );

    if (mounted) Navigator.pop(context); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message']),
        backgroundColor:
            response['status'] == 'success' ? Colors.green : Colors.red,
      ),
    );
  }

  void _toggleActive(Court court, CourtProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final response = await provider.toggleActive(court.id, !court.isActive);

    if (mounted) Navigator.pop(context); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message']),
        backgroundColor:
            response['status'] == 'success' ? Colors.green : Colors.red,
      ),
    );
  }

  void _showPeakPriceDialog(Court court, CourtProvider provider) {
    _peakPriceController.text = court.peakPrice?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Peak Hour Price'),
        content: TextField(
          controller: _peakPriceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Peak Price (per hour)',
            prefixText: 'रू ',
            hintText: 'Leave empty to remove peak pricing',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final peakPrice = _peakPriceController.text.isNotEmpty
                  ? int.parse(_peakPriceController.text)
                  : null;

              final response = await provider.setPeakPrice(court.id, peakPrice);

              if (mounted) Navigator.pop(context); // Close loading dialog

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(response['message']),
                  backgroundColor: response['status'] == 'success'
                      ? Colors.green
                      : Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showEditCourtDialog(String courtNumber, Court court) {
    // Create local copies for the dialog
    TextEditingController localCourtNumberController =
        TextEditingController(text: court.courtNumber);
    TextEditingController localBasePriceController =
        TextEditingController(text: court.basePrice.toString());
    TextEditingController localPeakPriceController =
        TextEditingController(text: court.peakPrice?.toString() ?? '');
    String localSelectedCourtType = court.courtType;
    List<String> localSelectedAmenities = List.from(court.amenities);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Court'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Court Number
                  TextField(
                    controller: localCourtNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Court Number',
                      hintText: 'e.g., 1, 2, A, B',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Court Type
                  DropdownButtonFormField(
                    value: localSelectedCourtType,
                    items: _courtTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        localSelectedCourtType = value.toString();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Court Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Base Price
                  TextField(
                    controller: localBasePriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Base Price (per hour)',
                      prefixText: 'रू ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Peak Price (Optional)
                  TextField(
                    controller: localPeakPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Peak Price (per hour) - Optional',
                      prefixText: 'रू ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Amenities Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Amenities',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableAmenities.map((amenity) {
                          final isSelected =
                              localSelectedAmenities.contains(amenity);
                          return FilterChip(
                            label: Text(amenity),
                            selected: isSelected,
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  localSelectedAmenities.add(amenity);
                                } else {
                                  localSelectedAmenities.remove(amenity);
                                }
                              });
                            },
                            backgroundColor: Colors.grey.shade100,
                            selectedColor: Colors.green.shade100,
                            checkmarkColor: Colors.green,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.green
                                  : Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.green
                                    : Colors.grey.shade300,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () => _updateCourt(
                  court.id,
                  localCourtNumberController.text,
                  localBasePriceController.text,
                  localPeakPriceController.text,
                  localSelectedCourtType,
                  localSelectedAmenities,
                  ctx,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('UPDATE'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _updateCourt(
    int courtId,
    String courtNumber,
    String basePrice,
    String peakPrice,
    String courtType,
    List<String> amenities,
    BuildContext dialogContext,
  ) async {
    if (courtNumber.isEmpty || basePrice.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(dialogContext); // Close dialog

    final provider = Provider.of<CourtProvider>(context, listen: false);

    final courtData = {
      'courtNumber': courtNumber,
      'courtType': courtType,
      'basePrice': int.parse(basePrice),
      'peakPrice': peakPrice.isNotEmpty ? int.parse(peakPrice) : null,
      'amenities': amenities,
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final response = await provider.updateCourt(courtId, courtData);

    if (mounted) Navigator.pop(context); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message']),
        backgroundColor:
            response['status'] == 'success' ? Colors.green : Colors.red,
      ),
    );

    if (response['status'] == 'success') {
      _loadCourts();
    }
  }

  void _showDeleteDialog(Court court, CourtProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Court'),
        content:
            Text('Are you sure you want to delete Court ${court.courtNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteCourt(court.id, provider);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _deleteCourt(int courtId, CourtProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final response = await provider.deleteCourt(courtId);

    if (mounted) Navigator.pop(context); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message']),
        backgroundColor:
            response['status'] == 'success' ? Colors.green : Colors.red,
      ),
    );

    if (response['status'] == 'success') {
      _loadCourts();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
