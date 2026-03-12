import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AdminAllFutsalsScreen extends StatefulWidget {
  const AdminAllFutsalsScreen({super.key});

  @override
  State<AdminAllFutsalsScreen> createState() => _AdminAllFutsalsScreenState();
}

class _AdminAllFutsalsScreenState extends State<AdminAllFutsalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadAllFutsals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Futsals"), centerTitle: true),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adminProvider.allFutsals.isEmpty) {
            return const Center(child: Text("No futsals found"));
          }

          return RefreshIndicator(
            onRefresh: () => adminProvider.loadAllFutsals(),
            child: ListView.builder(
              itemCount: adminProvider.allFutsals.length,
              itemBuilder: (_, index) {
                final futsal = adminProvider.allFutsals[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    title: Text(futsal['name'] ?? 'Futsal'),
                    subtitle: Text(futsal['owner']?['fullName'] ?? 'Owner'),
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