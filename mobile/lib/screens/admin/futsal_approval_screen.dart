import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class FutsalApprovalScreen extends StatefulWidget {
  const FutsalApprovalScreen({super.key});

  @override
  State<FutsalApprovalScreen> createState() => _FutsalApprovalScreenState();
}

class _FutsalApprovalScreenState extends State<FutsalApprovalScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false)
          .loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Futsal Approvals"),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {

          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adminProvider.pendingFutsals.isEmpty) {
            return const Center(
              child: Text(
                "No pending futsals for approval",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await adminProvider.loadDashboardStats();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: adminProvider.pendingFutsals.length,
              itemBuilder: (context, index) {
                final futsal = adminProvider.pendingFutsals[index];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// FUTSAL NAME
                        Text(
                          futsal["name"] ?? "Unnamed Futsal",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        /// LOCATION
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 18),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                futsal["address"] ?? "Unknown location",
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        /// OWNER
                        if (futsal["owner"]?["fullName"] != null)
                          Text(
                            "Owner: ${futsal["owner"]?["fullName"] ?? "Unknown"}",
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),

                        const SizedBox(height: 12),

                        /// ACTION BUTTONS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [

                            /// REJECT BUTTON
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              icon: const Icon(Icons.close),
                              label: const Text("Reject"),
                              onPressed: () {
                                _showRejectDialog(
                                  context,
                                  futsal["id"],
                                );
                              },
                            ),

                            const SizedBox(width: 10),

                            /// APPROVE BUTTON
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              icon: const Icon(Icons.check),
                              label: const Text("Approve"),
                              onPressed: () async {

                                final result = await adminProvider
                                    .approveFutsal(futsal["id"]);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result["message"]),
                                  ),
                                );
                              },
                            ),
                          ],
                        )
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

  /// =========================
  /// REJECT FUTSAL DIALOG
  /// =========================
  void _showRejectDialog(BuildContext context, int futsalId) {
    final TextEditingController reasonController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reject Futsal"),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              hintText: "Enter rejection reason",
            ),
          ),
          actions: [

            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),

            Consumer<AdminProvider>(
              builder: (context, adminProvider, _) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text("Reject"),
                  onPressed: () async {

                    final result = await adminProvider.rejectFutsal(
                      futsalId,
                      reasonController.text,
                    );

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result["message"]),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}