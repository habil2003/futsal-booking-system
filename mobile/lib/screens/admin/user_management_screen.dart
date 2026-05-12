import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _searchQuery = '';
  String _roleFilter = 'All';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          Consumer<AdminProvider>(
            builder: (context, adminProvider, _) {
              final blockedCount = adminProvider.allUsers
                  .where((u) =>
                      (u['status'] == 'Banned' ||
                          u['status'] == 'Suspended' ||
                          u['isActive'] == false))
                  .length;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$blockedCount Blocked',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter users by search, role, and status
          var users = adminProvider.allUsers.where((user) {
            final query = _searchQuery.toLowerCase();
            final matchesSearch = _searchQuery.isEmpty ||
                (user['fullName'] ?? '').toLowerCase().contains(query) ||
                (user['email'] ?? '').toLowerCase().contains(query) ||
                (user['contact'] ?? '').toLowerCase().contains(query);

            final matchesRole =
                _roleFilter == 'All' || user['role'] == _roleFilter;
            final matchesStatus =
                _statusFilter == 'All' || user['status'] == _statusFilter;

            return matchesSearch && matchesRole && matchesStatus;
          }).toList();

          return Column(
            children: [
              // Search and filter bar
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by name, email or contact...',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.green),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () =>
                                    setState(() => _searchQuery = ''),
                              )
                            : null,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Role', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<String>(
                                  value: _roleFilter,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(value: 'All', child: Text('All Roles')),
                                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                                    DropdownMenuItem(value: 'User', child: Text('User')),
                                    DropdownMenuItem(value: 'Guest', child: Text('Guest')),
                                    DropdownMenuItem(value: 'Moderator', child: Text('Moderator')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) setState(() => _roleFilter = value);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<String>(
                                  value: _statusFilter,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(value: 'All', child: Text('All Status')),
                                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                                    DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                                    DropdownMenuItem(value: 'Banned', child: Text('Banned')),
                                    DropdownMenuItem(value: 'Suspended', child: Text('Suspended')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) setState(() => _statusFilter = value);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_roleFilter != 'All' || _statusFilter != 'All' || _searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _roleFilter = 'All';
                                _statusFilter = 'All';
                              });
                            },
                            child: const Text('Clear All Filters'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text('${users.length} users', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('No users found', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => adminProvider.loadAllUsers(),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: DataTable(
                                  columnSpacing: 0,
                                  horizontalMargin: 0,
                                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                                  dataRowMinHeight: 56,
                                  dataRowMaxHeight: 64,
                                  columns: const [
                                    DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                    DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                    DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                    DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                    DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                    DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Joined Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                    DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Last Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                    DataColumn(label: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                                  ],
                                  rows: List<DataRow>.generate(users.length, (index) {
                                    final user = users[index];
                                    final fullName = user['fullName'] ?? 'Unknown';
                                    final email = user['email'] ?? '';
                                    final contact = user['contact'] ?? '';
                                    final role = user['role'] ?? 'User';
                                    final status = user['status'] ?? 'Active';
                                    final joinedDate = user['joinedDate'] ?? '';
                                    final lastActive = user['lastActive'] ?? '';
                                    final isAdmin = role == 'Admin';
                                    final isOwner = role == 'Owner';
                                    final isApproved = user['isApproved'] ?? false;
                                    final isActive = user['isActive'] ?? true;
                                    final userId = user['id'];

                                    Color statusColor;
                                    switch (status) {
                                      case 'Active':    statusColor = Colors.green; break;
                                      case 'Inactive':  statusColor = Colors.grey; break;
                                      case 'Banned':    statusColor = Colors.red; break;
                                      case 'Suspended': statusColor = Colors.orange; break;
                                      default:          statusColor = Colors.grey;
                                    }

                                    return DataRow(
                                      color: WidgetStateProperty.resolveWith(
                                          (states) => index.isEven ? Colors.grey.shade50 : Colors.white),
                                      cells: [
                                        // User
                                        DataCell(
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor: isAdmin ? Colors.red.shade100 : isOwner ? Colors.orange.shade100 : Colors.green.shade100,
                                                  child: Text(fullName[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: isAdmin ? Colors.red : isOwner ? Colors.orange : Colors.green)),
                                                ),
                                                const SizedBox(width: 8),
                                                Flexible(child: Text(fullName, overflow: TextOverflow.ellipsis)),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Email
                                        DataCell(Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Text(email, overflow: TextOverflow.ellipsis))),
                                        // Contact
                                        DataCell(Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Text(contact.isEmpty ? '—' : contact, overflow: TextOverflow.ellipsis))),
                                        // Role
                                        DataCell(
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isAdmin ? Colors.red.shade50 : isOwner ? Colors.orange.shade50 : Colors.green.shade50,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(role, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isAdmin ? Colors.red : isOwner ? Colors.orange : Colors.green)),
                                            ),
                                          ),
                                        ),
                                        // Status
                                        DataCell(
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
                                            ),
                                          ),
                                        ),
                                        // Joined Date
                                        DataCell(Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Text(joinedDate))),
                                        // Last Active
                                        DataCell(Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Text(lastActive))),
                                        // Actions
                                        DataCell(
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, size: 18),
                                                  tooltip: 'Edit',
                                                  onPressed: () {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Edit $fullName – coming soon')),
                                                    );
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                                  tooltip: 'Delete',
                                                  onPressed: () async {
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        title: const Text('Delete User'),
                                                        content: Text('Delete $fullName permanently? This cannot be undone.'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(ctx, false),
                                                            child: const Text('CANCEL'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(ctx, true),
                                                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                            child: const Text('DELETE'),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm == true) {
                                                      try {
                                                        final result = await adminProvider.deleteUser(userId);
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text(result['message'] ?? 'User deleted successfully'),
                                                              backgroundColor: Colors.green,
                                                            ),
                                                          );
                                                          // Refresh the list
                                                          adminProvider.loadAllUsers();
                                                        }
                                                      } catch (e) {
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('Failed to delete user'), backgroundColor: Colors.red),
                                                          );
                                                        }
                                                      }
                                                    }
                                                  },
                                                ),
                                                // Block / Unblock
                                                IconButton(
                                                  icon: Icon(
                                                    isActive ? Icons.block : Icons.check_circle,
                                                    size: 18,
                                                    color: isActive ? Colors.red : Colors.green,
                                                  ),
                                                  tooltip: isActive ? 'Block User' : 'Unblock User',
                                                  onPressed: () async {
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        title: Text(
                                                          isActive ? 'Block User' : 'Unblock User',
                                                          style: TextStyle(color: isActive ? Colors.red : Colors.green),
                                                        ),
                                                        content: Text(
                                                          isActive
                                                              ? 'Block $fullName? They will be unable to log in.'
                                                              : 'Unblock $fullName? They will regain access.',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(ctx, false),
                                                            child: const Text('CANCEL'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(ctx, true),
                                                            style: TextButton.styleFrom(foregroundColor: isActive ? Colors.red : Colors.green),
                                                            child: Text(isActive ? 'BLOCK' : 'UNBLOCK'),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm == true) {
                                                      final result = await adminProvider.toggleUserStatus(userId, !isActive);
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text(result['message']),
                                                            backgroundColor: result['status'] == 'success' ? Colors.green : Colors.red,
                                                          ),
                                                        );
                                                        // Refresh list to reflect changes
                                                        adminProvider.loadAllUsers();
                                                      }
                                                    }
                                                  },
                                                ),
                                                // Approve owner (if pending)
                                                if (isOwner && !isApproved)
                                                  IconButton(
                                                    icon: const Icon(Icons.check, size: 18, color: Colors.green),
                                                    tooltip: 'Approve Owner',
                                                    onPressed: () async {
                                                      final result = await adminProvider.approveOwner(userId);
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text(result['message']),
                                                            backgroundColor: result['status'] == 'success' ? Colors.green : Colors.red,
                                                          ),
                                                        );
                                                        adminProvider.loadAllUsers();
                                                      }
                                                    },
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ),
                            );
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
}