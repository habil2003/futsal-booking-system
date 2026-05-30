import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/futsal.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/favorite_provider.dart';
import '../../../../utils/responsive.dart';

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
    final amenities = futsal.getAllAmenities();
    final minPrice = futsal.getMinPrice();
    final courtTypes = futsal.getCourtTypes();
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final imageHeight = Responsive.getCardImageHeight(context);
    
    // Responsive card width with maximum limit
    final cardWidth = isDesktop 
        ? 320.0  // Fixed max width for desktop
        : isTablet
            ? 280.0  // Fixed width for tablet
            : double.infinity;  // Full width for mobile

    return Container(
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 320 : isTablet ? 280 : double.infinity,
        minWidth: isDesktop ? 280 : isTablet ? 240 : 200,
      ),
      width: cardWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Material(
          color: Colors.transparent,
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
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : Colors.grey.shade600,
                                size: 18,
                              ),
                              onPressed: () async {
                                final auth = Provider.of<AuthProvider>(context,
                                    listen: false);
                                if (!auth.isAuthenticated) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please log in to save favorites'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                await favProvider.toggleFavorite(futsal.id);
                              },
                              padding: EdgeInsets.zero,
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
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 10,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                futsal.averageRating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
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
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        futsal.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),

                      // Court Type Badges
                      if (courtTypes.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: courtTypes.map((type) {
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
                                  fontSize: 10,
                                  color: isIndoor 
                                      ? Colors.blue.shade700 
                                      : Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      
                      const SizedBox(height: 6),

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              futsal.address.split(',').first,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.near_me,
                                    size: 8,
                                    color: Colors.blue.shade600,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    futsal.distance! < 1
                                        ? '${(futsal.distance! * 1000).round()}m'
                                        : '${futsal.distance!.toStringAsFixed(1)}km',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Amenities
                      if (amenities.isNotEmpty)
                        SizedBox(
                          height: 24,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: amenities.length > 3 ? 3 : amenities.length,
                            itemBuilder: (context, index) {
                              final amenity = amenities[index];
                              return Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getAmenityIcon(amenity),
                                      size: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      amenity.length > 10
                                          ? '${amenity.substring(0, 8)}...'
                                          : amenity,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 10),

                      // Price and Book Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Price
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Starting from',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                if (minPrice != null)
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'रू ',
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(
                                          text: minPrice.toStringAsFixed(0),
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '/hr',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 10,
                                            fontWeight: FontWeight.normal,
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
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          
                          // Book Button
                          SizedBox(
                            width: 80,
                            height: 32,
                            child: ElevatedButton(
                              onPressed: onTap,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 32),
                              ),
                              child: const Text(
                                'Book',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
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
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    final lower = amenity.toLowerCase();
    if (lower.contains('parking')) return Icons.local_parking;
    if (lower.contains('water')) return Icons.local_drink;
    if (lower.contains('light')) return Icons.light_mode;
    if (lower.contains('chair')) return Icons.chair;
    if (lower.contains('shower')) return Icons.shower;
    if (lower.contains('wifi')) return Icons.wifi;
    if (lower.contains('ac')) return Icons.ac_unit;
    return Icons.fitness_center;
  }
}