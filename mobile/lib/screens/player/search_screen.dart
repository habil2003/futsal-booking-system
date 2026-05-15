import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/futsal.dart';
import '../../providers/futsal_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import 'futsal_details_screen.dart';
import './home_screen.dart'; 

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';

  // Recent searches
  List<String> _recentSearches = [];
  static const int _maxHistory = 10;

  // 🔁 Query persistence
  Future<void>? _saveQueryDebounce;

  String get _historyKey {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  final userId = auth.user?.id ?? 'guest';
  return 'recent_searches_$userId';
}

String get _userQueryKey {
  final auth = Provider.of<AuthProvider>(context, listen: false);
  final userId = auth.user?.id ?? 'guest';
  return 'saved_search_query_$userId';
}

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadSavedQuery();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  // ---------- Persistent storage ----------
  Future<void> _loadRecentSearches() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getStringList(_historyKey) ?? [];
  setState(() {
    _recentSearches = stored;
  });
}

Future<void> _saveRecentSearches() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(_historyKey, _recentSearches);
}

  // --- Query persistence ---
  Future<void> _loadSavedQuery() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_userQueryKey) ?? '';
  if (saved.isNotEmpty) {
    _searchController.text = saved;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: saved.length),
    );
    setState(() => _query = saved);
  }
}

Future<void> _saveQuery(String value) async {
  _saveQueryDebounce = Future.delayed(const Duration(milliseconds: 300), () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userQueryKey, value);
  });
}

  // ---------- Recent Searches ----------
  void _addToRecent(String term) {
    if (term.trim().isEmpty) return;
    setState(() {
      _recentSearches.remove(term);
      _recentSearches.insert(0, term);
      if (_recentSearches.length > _maxHistory) {
        _recentSearches = _recentSearches.sublist(0, _maxHistory);
      }
    });
    _saveRecentSearches();
  }

  void _removeRecent(String term) {
    setState(() {
      _recentSearches.remove(term);
    });
    _saveRecentSearches();
  }

  void _clearAllRecent() {
    setState(() {
      _recentSearches.clear();
    });
    _saveRecentSearches();
  }

  void _searchWithTerm(String term) {
    _searchController.text = term;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: term.length),
    );
    setState(() => _query = term);
    _saveQuery(term);
  }

  // ---------- Filtering ----------
  List<Futsal> _filteredFutsals() {
    final provider = Provider.of<FutsalProvider>(context, listen: false);
    if (_query.isEmpty) return [];
    return provider.futsals.where((f) {
      return f.name.toLowerCase().contains(_query.toLowerCase()) ||
          f.address.toLowerCase().contains(_query.toLowerCase());
    }).toList();
  }

  // ---------- Navigation ----------
  void _onBookPressed(BuildContext context, Futsal futsal) async {
    _addToRecent(futsal.name);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      final didLogin = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (didLogin == true) {
        _proceedToBooking(context, futsal);
      }
    } else {
      _proceedToBooking(context, futsal);
    }
  }

  void _proceedToBooking(BuildContext context, Futsal futsal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FutsalDetailsScreen(
          futsal: futsal,
          initialTabIndex: 1,
        ),
      ),
    );
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    final results = _filteredFutsals();
    final futsalProvider = Provider.of<FutsalProvider>(context);
    final recommended = futsalProvider.futsals.take(6).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
         icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
  context,
  '/player/home',
  (route) => false,
),
),
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: (value) {
              setState(() => _query = value);
              _saveQuery(value);                // persist query
            },
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search by name or location...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.search, color: Colors.green),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                        _saveQuery('');          // clear saved query
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: _query.isEmpty ? _buildDefaultView(recommended) : _buildResultsView(results),
    );
  }

  // ---------- Default view (recent + recommended) ----------
  Widget _buildDefaultView(List<Futsal> recommended) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
                    if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Searches',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: _clearAllRecent,
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _recentSearches.map((term) {
                return GestureDetector(
                  onTap: () => _searchWithTerm(term),
                  child: Chip(
                    label: Text(term),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeRecent(term),
                    backgroundColor: Colors.green.shade50,
                    labelStyle: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Recommended Grounds
          if (recommended.isNotEmpty) ...[
            const Text('Recommended Grounds',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...recommended.map((futsal) => _buildResultCard(futsal)),
          ],
        ],
      ),
    );
  }

  // ---------- Search results view ----------
  Widget _buildResultsView(List<Futsal> results) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No futsals found', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final futsal = results[index];
        return _buildResultCard(futsal);
      },
    );
  }

  Widget _buildResultCard(Futsal futsal) {
    final imageUrl = futsal.images.isNotEmpty
        ? futsal.images[0]
        : 'https://via.placeholder.com/300x180?text=Futsal';
    final rating = futsal.averageRating ?? 4.5;
    final price = futsal.getMinPrice();

    return GestureDetector(
      onTap: () => _onBookPressed(context, futsal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100,
                  height: 100,
                  color: Colors.green.shade50,
                  child: const Icon(Icons.sports_soccer, color: Colors.green, size: 40),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(futsal.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(futsal.address,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ...List.generate(5, (i) => Icon(
                        i < rating.round() ? Icons.star : Icons.star_border,
                        size: 14, color: Colors.amber,
                      )),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    price != null ? 'From Rs. ${price.toStringAsFixed(0)}/hr' : 'Price varies',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                  ),
                ],
              ),
            ),
            Consumer<FavoriteProvider>(
              builder: (context, favProvider, child) {
                final isFav = favProvider.isFavorite(futsal.id);
                return IconButton(
                  icon: Icon(
                    isFav ? Icons.bookmark : Icons.bookmark_border,
                    color: isFav ? Colors.green.shade700 : Colors.grey.shade400,
                    size: 28,
                  ),
                  onPressed: () async {
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    if (!auth.isAuthenticated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please log in to save favorites'), backgroundColor: Colors.orange),
                      );
                      return;
                    }
                    final success = await favProvider.toggleFavorite(futsal.id);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isFav ? 'Removed from favorites' : 'Added to favorites'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}