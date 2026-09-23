import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/futsal.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/favorite_provider.dart';

class FutsalCard extends StatelessWidget {
  final Futsal futsal;
  final VoidCallback onTap;

  const FutsalCard({
    super.key,
    required this.futsal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;

    // Responsive dimensions
    final imageHeight = isDesktop
        ? 160.0
        : isTablet
            ? 140.0
            : 120.0;
    final titleFontSize = isDesktop
        ? 18.0
        : isTablet
            ? 16.0
            : 15.0;
    final bodyFontSize = isDesktop
        ? 13.0
        : isTablet
            ? 12.0
            : 11.0;
    final priceFontSize = isDesktop
        ? 18.0
        : isTablet
            ? 16.0
            : 15.0;
    final buttonWidth = isDesktop
        ? 100.0
        : isTablet
            ? 90.0
            : 80.0;
    final buttonHeight = isDesktop
        ? 36.0
        : isTablet
            ? 34.0
            : 32.0;
    final cardPadding = isDesktop
        ? 14.0
        : isTablet
            ? 12.0
            : 10.0;
    final iconSize = isDesktop
        ? 16.0
        : isTablet
            ? 14.0
            : 12.0;
    final spacing = isDesktop
        ? 10.0
        : isTablet
            ? 8.0
            : 6.0;
    final cardCornerRadius = isDesktop
        ? 16.0
        : isTablet
            ? 14.0
            : 12.0;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardCornerRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                Image.network(
                  futsal.images.isNotEmpty ? futsal.images.first : '',
                  height: imageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: imageHeight,
                      width: double.infinity,
                      color: Colors.green.shade50,
                      child: const Center(
                        child: Icon(
                          Icons.sports_soccer,
                          size: 40,
                          color: Colors.green,
                        ),
                      ),
                    );
                  },
                ),
                // Favorite Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<FavoriteProvider>(
                    builder: (context, favProvider, child) {
                      final isFav = favProvider.isFavorite(futsal.id);
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.grey.shade600,
                            size: iconSize,
                          ),
                          onPressed: () async {
                            final auth = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            if (!auth.isAuthenticated) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please log in to save favorites',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            await favProvider.toggleFavorite(futsal.id);
                          },
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                      );
                    },
                  ),
                ),
                // Rating Badge
                if (futsal.averageRating != null)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: bodyFontSize,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            futsal.averageRating!.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: bodyFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // Content Section
            Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    futsal.name,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: spacing * 0.5),

                  // Court Type Badges (max 2)
                  if (futsal.getCourtTypes().isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: futsal.getCourtTypes().take(2).map((type) {
                        final isIndoor = type.toLowerCase() == 'indoor';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isIndoor
                                ? Colors.blue.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: bodyFontSize - 1,
                              color: isIndoor
                                  ? Colors.blue.shade700
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  SizedBox(height: spacing),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: iconSize - 2,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          futsal.address.split(',').first,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: bodyFontSize,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (futsal.distance != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            futsal.distance! < 1
                                ? '${(futsal.distance! * 1000).round()}m'
                                : '${futsal.distance!.toStringAsFixed(1)}km',
                            style: TextStyle(
                              fontSize: bodyFontSize - 1,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: spacing),

                  // Amenities (max 3)
                  if (futsal.getAllAmenities().isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: futsal.getAllAmenities().take(3).map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            amenity.length > 10
                                ? '${amenity.substring(0, 8)}...'
                                : amenity,
                            style: TextStyle(
                              fontSize: bodyFontSize - 1,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  SizedBox(height: spacing),

                  // Price and Book Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Starting from',
                              style: TextStyle(
                                fontSize: bodyFontSize - 1,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            if (futsal.getMinPrice() != null)
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'रू ',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: priceFontSize - 2,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: futsal
                                          .getMinPrice()!
                                          .toStringAsFixed(0),
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: priceFontSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '/hr',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: bodyFontSize - 1,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Text(
                                'Contact for price',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: bodyFontSize,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Book Button
                      SizedBox(
                        width: buttonWidth,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'Book',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: bodyFontSize,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
