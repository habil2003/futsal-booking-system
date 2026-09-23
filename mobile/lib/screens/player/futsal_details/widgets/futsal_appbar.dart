import 'package:flutter/material.dart';
import '/models/futsal.dart';
import '../../../../widgets/fullscreen_image_viewer.dart';

class FutsalAppBar extends StatelessWidget {
  final Futsal futsal;
  final int selectedImageIndex;
  final Function(int) onPageChanged;
  final bool isProcessing;
  final VoidCallback onBack;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  final bool isFavorite;

  const FutsalAppBar({
    super.key,
    required this.futsal,
    required this.selectedImageIndex,
    required this.onPageChanged,
    required this.isProcessing,
    required this.onBack,
    required this.onFavorite,
    required this.onShare,
    this.isFavorite = false,
  });

  void _showFullScreenImage(BuildContext context, int index) {
    if (futsal.images.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenImageViewer(
          images: futsal.images,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.green,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Wrap PageView with GestureDetector to make images clickable
            GestureDetector(
              onTap: () => _showFullScreenImage(context, selectedImageIndex),
              child: PageView.builder(
                itemCount: futsal.images.isNotEmpty ? futsal.images.length : 1,
                onPageChanged: onPageChanged,
                itemBuilder: (context, index) {
                  return futsal.images.isNotEmpty
                      ? Image.network(
                          futsal.images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder();
                },
              ),
            ),
            _buildImageIndicators(),
            _buildGradient(),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onBack,
      ),
      actions: [
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: Colors.white,
          ),
          onPressed: isProcessing ? null : onFavorite,
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: isProcessing ? null : onShare,
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.green.shade200,
      child: Center(
        child: Icon(
          Icons.sports_soccer,
          size: 80,
          color: Colors.green.shade400,
        ),
      ),
    );
  }

  Widget _buildImageIndicators() {
    if (futsal.images.isEmpty || futsal.images.length <= 1) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          futsal.images.length,
          (index) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selectedImageIndex == index
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradient() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.5),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}