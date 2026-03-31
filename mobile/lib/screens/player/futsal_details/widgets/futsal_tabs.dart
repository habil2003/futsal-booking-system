// lib/screens/player/futsal_details/widgets/futsal_tabs.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'about_tab.dart';
import 'slots_tab.dart';
import 'reviews_tab.dart';
import '../../../../models/futsal.dart';
import '../../../../providers/court_provider.dart';

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
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    
    // Fetch courts when tab loads
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
    return FutureBuilder<void>(
      future: _courtsFuture,
      builder: (context, snapshot) {
        // While loading, show the tabs with loading indicator in About tab
        return Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  AboutTab(
                    futsal: widget.futsal,
                    isLoading: snapshot.connectionState != ConnectionState.done,
                  ),
                  SlotsTab(futsal: widget.futsal),
                  ReviewsTab(futsal: widget.futsal),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.green,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.green,
        tabs: const [
          Tab(text: 'About', icon: Icon(Icons.info)),
          Tab(text: 'Slots', icon: Icon(Icons.access_time)),
          Tab(text: 'Reviews', icon: Icon(Icons.star)),
        ],
      ),
    );
  }
}