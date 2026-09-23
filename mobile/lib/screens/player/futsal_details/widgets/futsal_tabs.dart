import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../utils/responsive.dart';
import '../../../../utils/app_colors.dart';
import 'about_tab.dart';
import 'reviews_tab.dart';
import '../../../../models/futsal.dart';
import '../../../../providers/court_provider.dart';
import 'check_availability_screen.dart';   // 🆕 availability page

class FutsalTabs extends StatefulWidget {
  final Futsal futsal;
  final int initialTabIndex;

  const FutsalTabs({
    super.key,
    required this.futsal,
    required this.initialTabIndex,
  });

  @override
  State<FutsalTabs> createState() => _FutsalTabsState();
}

class _FutsalTabsState extends State<FutsalTabs> with TickerProviderStateMixin {
  late TabController _tabController;
  late Future<void> _courtsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,                    // Only About and Reviews
      vsync: this,
      initialIndex: widget.initialTabIndex > 1 ? 1 : widget.initialTabIndex, // prevent index out of range
    );
    _courtsFuture = _fetchCourts();
  }
  
  Future<void> _fetchCourts() async {
    final courtProvider = Provider.of<CourtProvider>(context, listen: false);
    await courtProvider.loadCourts(widget.futsal.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final tabFontSize = isDesktop ? 16.0 : 14.0;
    
    return FutureBuilder<void>(
      future: _courtsFuture,
      builder: (context, snapshot) {
        return Column(
          children: [
            // ── Tab Bar ──
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.secondaryText,
                indicatorColor: AppColors.primary,
                labelStyle: TextStyle(fontSize: tabFontSize),
                unselectedLabelStyle: TextStyle(fontSize: tabFontSize),
                tabs: const [
                  Tab(text: 'About', icon: Icon(Icons.info_outline)),
                  Tab(text: 'Reviews', icon: Icon(Icons.star_border)),
                ],
              ),
            ),
            // ── Tab Content ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  AboutTab(
                    futsal: widget.futsal,
                    isLoading: snapshot.connectionState != ConnectionState.done,
                  ),
                  ReviewsTab(futsal: widget.futsal),
                ],
              ),
            ),
            // ── Check Availability Button ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckAvailabilityScreen(futsal: widget.futsal),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Check Availability',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}