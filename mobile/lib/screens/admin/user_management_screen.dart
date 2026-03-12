import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();

    // Load all users when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Users"),
        centerTitle: true,
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adminProvider.allUsers.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          return RefreshIndicator(
            onRefresh: () => adminProvider.loadAllUsers(),
            child: ListView.builder(
              itemCount: adminProvider.allUsers.length,
              itemBuilder: (_, index) {
                final user = adminProvider.allUsers[index];
                final isOwner = user['role'] == 'OWNER';
                final isApproved = user['isApproved'] ?? false;
                final isActive = user['isActive'] ?? true;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    title: Text(user['fullName'] ?? 'User'),
                    subtitle: Text(user['email'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Approve Owner
                        if (isOwner && !isApproved)
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            tooltip: 'Approve Owner',
                            onPressed: () async {
                              final result = await adminProvider.approveOwner(user['id']);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result['message'])),
                              );
                            },
                          ),

                        // Block/Unblock
                        IconButton(
                          icon: Icon(
                            isActive ? Icons.lock_open : Icons.lock,
                            color: isActive ? Colors.orange : Colors.red,
                          ),
                          tooltip: isActive ? 'Block User' : 'Activate User',
                          onPressed: () async {
                            final result = await adminProvider.toggleUserStatus(user['id'], !isActive);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result['message'])),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}