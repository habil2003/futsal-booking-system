import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AdminAllFutsalsScreen extends StatefulWidget {
  const AdminAllFutsalsScreen({super.key});

  @override
  State<AdminAllFutsalsScreen> createState() => _AdminAllFutsalsScreenState();
}

class _AdminAllFutsalsScreenState extends State<AdminAllFutsalsScreen> {
  String _searchQuery = '';
  bool _showDeactivated = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadAllFutsals();
    });
  }

  bool _canDelete(Map<String, dynamic> futsal) {
    final hasBookings = (futsal['_count']?['bookings'] ?? 0) > 0;
    return !hasBookings;
  }

  String _getStatusText(Map<String, dynamic> futsal) {
    final status = futsal['status'] ?? 'PENDING';
    if (status == 'ACTIVE') return 'Active';
    if (status == 'DEACTIVATED') return 'Deactivated';
    if (status == 'PENDING') return 'Pending Approval';
    if (status == 'PENDING_PAYMENT') return 'Payment Pending';
    return status;
  }

  Color _getStatusColor(Map<String, dynamic> futsal) {
    final status = futsal['status'] ?? 'PENDING';
    if (status == 'ACTIVE') return Colors.green;
    if (status == 'DEACTIVATED') return Colors.orange;
    if (status == 'PENDING') return Colors.blue;
    if (status == 'PENDING_PAYMENT') return Colors.orange;
    return Colors.grey;
  }

  void _showDeactivateDialog(BuildContext context, Map<String, dynamic> futsal, AdminProvider adminProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Futsal'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deactivate "${futsal['name']}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, size: 18, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Owner will NOT be able to reactivate this futsal. Only admin can reactivate.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await adminProvider.adminDeactivateFutsal(futsal['id']);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: Colors.orange,
                  ),
                );
                if (result['status'] == 'success') {
                  adminProvider.loadAllFutsals();
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _showActivateDialog(BuildContext context, Map<String, dynamic> futsal, AdminProvider adminProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Activate Futsal'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text('Activate "${futsal['name']}"?\n\nThis futsal will become visible to players again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await adminProvider.adminActivateFutsal(futsal['id']);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: Colors.green,
                  ),
                );
                if (result['status'] == 'success') {
                  adminProvider.loadAllFutsals();
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> futsal, AdminProvider adminProvider) {
    final hasPayment = futsal['registrationFeePaid'] == true;
    final registrationFeeAmount = futsal['registrationFeeAmount'] ?? 10;
    final hasBookings = (futsal['_count']?['bookings'] ?? 0) > 0;
    
    if (hasBookings) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete futsal with existing bookings.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Futsal'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${futsal['name']}"?'),
            const SizedBox(height: 12),
            if (hasPayment)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, size: 18, color: Colors.orange.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Registration fee of ₹${registrationFeeAmount.toStringAsFixed(0)} has been paid. No refund will be issued.',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await adminProvider.deleteFutsal(futsal['id']);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['status'] == 'success' ? Colors.red : Colors.red.shade300,
                  ),
                );
                if (result['status'] == 'success') {
                  adminProvider.loadAllFutsals();
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showViewDetails(BuildContext context, Map<String, dynamic> futsal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              futsal['name'] ?? 'Unnamed Futsal',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              futsal['address'] ?? '',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (futsal['description'] != null) ...[
              const SizedBox(height: 12),
              Text(futsal['description'], style: const TextStyle(fontSize: 14)),
            ],
            const Divider(height: 24),
            const Text('Owner Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.person, futsal['owner']?['fullName'] ?? 'Unknown'),
            if (futsal['owner']?['email'] != null) ...[
              const SizedBox(height: 6),
              _buildDetailRow(Icons.email, futsal['owner']['email']),
            ],
            if (futsal['owner']?['phoneNumber'] != null) ...[
              const SizedBox(height: 6),
              _buildDetailRow(Icons.phone, futsal['owner']['phoneNumber']),
            ],
            const Divider(height: 24),
            const Text('Courts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (futsal['courts'] != null && (futsal['courts'] as List).isNotEmpty)
              ...(futsal['courts'] as List).map((court) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sports_soccer, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text('Court ${court['courtNumber']} • ${court['courtType']}'),
                      const Spacer(),
                      Text('रू ${court['basePrice']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ))
            else
              const Text('No courts added yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied: $value'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildContactButtons(BuildContext context, Map<String, dynamic> futsal) {
    final email = futsal['owner']?['email'];
    final phone = futsal['owner']?['phoneNumber'];

    return Row(
      children: [
        if (email != null)
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.email_outlined, size: 16),
              label: const Text('Email', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: BorderSide(color: Colors.blue.shade300),
              ),
              onPressed: () => _copyToClipboard(context, email, 'Email'),
            ),
          ),
        if (email != null && phone != null) const SizedBox(width: 8),
        if (phone != null)
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.phone_outlined, size: 16),
              label: const Text('Phone', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: BorderSide(color: Colors.green.shade300),
              ),
              onPressed: () => _copyToClipboard(context, phone, 'Phone'),
            ),
          ),
      ],
    );
  }

  

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Manage Futsals'),
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => Provider.of<AdminProvider>(context, listen: false).loadAllFutsals(),
        ),
      ],
    ),
    body: Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Colors.green));
        }

        // Debug: Print all statuses
final allStatuses = adminProvider.allFutsals.map((f) => f['status']).toSet();
print('All statuses in database: $allStatuses');
print('Total futsals: ${adminProvider.allFutsals.length}');

        // ✅ Filter futsals based on toggle - FIXED
        var futsals = adminProvider.allFutsals.where((f) {
          final status = f['status'] ?? '';
          
          // When toggle is ON: show ACTIVE + DEACTIVATED
          // When toggle is OFF: show only ACTIVE
          if (_showDeactivated) {
            return status == 'ACTIVE' || status == 'DEACTIVATED';
          } else {
            return status == 'ACTIVE';
          }
        }).toList();

        // Search filter
        if (_searchQuery.isNotEmpty) {
          futsals = futsals.where((f) {
            return (f['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (f['address'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }

        return Column(
          children: [
            // Search bar + Toggle
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name or address...',
                      prefixIcon: const Icon(Icons.search, color: Colors.green),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) {
                      setState(() {
                        _searchQuery = v;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // ✅ Toggle with better visibility
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _showDeactivated ? Colors.green.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _showDeactivated ? Colors.green.shade200 : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _showDeactivated ? Icons.visibility : Icons.visibility_off,
                              color: _showDeactivated ? Colors.green : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Show deactivated futsals',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _showDeactivated ? Colors.green.shade700 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _showDeactivated,
                          onChanged: (value) {
                            setState(() {
                              _showDeactivated = value;
                              print('Toggle changed to: $value'); // Debug print
                            });
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${futsals.length} futsals',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: futsals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            _showDeactivated 
                                ? 'No active or deactivated futsals found'
                                : 'No active futsals found',
                          ),
                          if (!_showDeactivated)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Toggle "Show deactivated futsals" to see deactivated ones',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => adminProvider.loadAllFutsals(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: futsals.length,
                        itemBuilder: (_, index) {
                          return _buildFutsalCard(context, futsals[index], adminProvider);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    ),
  );
}

  Widget _buildFutsalCard(BuildContext context, Map<String, dynamic> futsal, AdminProvider adminProvider) {
    final status = futsal['status'] ?? '';
    final isActive = status == 'ACTIVE';
    final isDeactivated = status == 'DEACTIVATED';
    final canDelete = _canDelete(futsal);
    final hasBookings = (futsal['_count']?['bookings'] ?? 0) > 0;
    final statusText = _getStatusText(futsal);
    final statusColor = _getStatusColor(futsal);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (futsal['images'] != null && (futsal['images'] as List).isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                futsal['images'][0],
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  color: Colors.green.shade50,
                  child: const Center(child: Icon(Icons.sports_soccer, size: 40, color: Colors.green)),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Status + Actions
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        futsal['name'] ?? 'Unnamed',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    // Admin Actions Menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (value) {
                        switch (value) {
                          case 'deactivate':
                            if (isActive) {
                              _showDeactivateDialog(context, futsal, adminProvider);
                            }
                            break;
                          case 'activate':
                            if (isDeactivated) {
                              _showActivateDialog(context, futsal, adminProvider);
                            }
                            break;
                          case 'delete':
                            if (canDelete) {
                              _showDeleteDialog(context, futsal, adminProvider);
                            }
                            break;
                          case 'view_details':
                            _showViewDetails(context, futsal);
                            break;
                        }
                      },
                      itemBuilder: (ctx) => [
                        if (isActive)
                          const PopupMenuItem(
                            value: 'deactivate',
                            child: Row(
                              children: [
                                Icon(Icons.block, size: 18, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Deactivate'),
                              ],
                            ),
                          ),
                        if (isDeactivated)
                          const PopupMenuItem(
                            value: 'activate',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, size: 18, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Activate'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'view_details',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 18, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('View Details'),
                            ],
                          ),
                        ),
                        if (canDelete && !hasBookings)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete Permanently'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Address
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        futsal['address'] ?? '',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Owner + Courts
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        futsal['owner']?['fullName'] ?? 'Unknown Owner',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ),
                    Icon(Icons.sports_soccer, size: 14, color: Colors.green.shade600),
                    Text(
                      ' ${futsal['courtCount'] ?? 0} courts',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),

                // Warning for bookings (only relevant for delete)
                if (hasBookings && isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, size: 14, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Has existing bookings - Cannot delete',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Deactivated notice
                if (isDeactivated)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info, size: 14, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This futsal is deactivated and not visible to players',
                              style: TextStyle(fontSize: 12, color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Contact buttons
                _buildContactButtons(context, futsal),
              ],
            ),
          ),
        ],
      ),
    );
  }
}