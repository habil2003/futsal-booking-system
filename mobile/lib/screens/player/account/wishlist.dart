import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:futsal_mobile/providers/favorite_provider.dart';
import 'package:futsal_mobile/providers/futsal_provider.dart';
import 'package:futsal_mobile/models/futsal.dart';
import 'package:futsal_mobile/screens/player/futsal_details_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final futsalProvider = Provider.of<FutsalProvider>(context);
    final favProvider = Provider.of<FavoriteProvider>(context);

    // Keep only the futsals that are marked as favorite
    final allFutsals = futsalProvider.futsals;
    final wishlist =
        allFutsals.where((f) => favProvider.isFavorite(f.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: wishlist.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No favourites yet.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wishlist.length,
              itemBuilder: (context, index) {
                final futsal = wishlist[index];
                return _buildWishlistCard(context, futsal);
              },
            ),
    );
  }

  Widget _buildWishlistCard(BuildContext context, Futsal futsal) {
    final imageUrl = futsal.images.isNotEmpty
        ? futsal.images[0]
        : 'https://via.placeholder.com/300x180?text=Futsal';
    final rating = futsal.averageRating ?? 4.5;
    final price = futsal.getMinPrice();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 80,
              height: 80,
              color: Colors.green.shade50,
              child: const Icon(Icons.sports_soccer,
                  color: Colors.green, size: 36),
            ),
          ),
        ),
        title: Text(futsal.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    futsal.address,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 13)),
                const Spacer(),
                Text(
                  price != null
                      ? 'Rs. ${price.toStringAsFixed(0)}/hr'
                      : 'Price varies',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red),
          onPressed: () {
            Provider.of<FavoriteProvider>(context, listen: false)
                .toggleFavorite(futsal.id);
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FutsalDetailsScreen(
                futsal: futsal,
                initialTabIndex: 1,
              ),
            ),
          );
        },
      ),
    );
  }
}