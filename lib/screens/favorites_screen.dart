import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:travelapp/models/travel_model.dart';
import 'package:travelapp/services/api_service.dart';
import 'package:travelapp/services/favorites_service.dart';
import 'package:travelapp/screens/travel_detail_screen.dart';
import 'package:travelapp/utils/image_utils.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Travel>> futureTravels;
  final FavoritesService _favoritesService = FavoritesService();
  Set<int> _favoriteIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    futureTravels = _fetchAllTravels();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _favoritesService.getFavoriteIds();
    setState(() {
      _favoriteIds = favorites;
    });
  }

  Future<List<Travel>> _fetchAllTravels() async {
    try {
      final travels = await ApiService().fetchTravels();
      return travels;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Алдаа: $e')),
        );
      }
      return [];
    }
  }

  Future<void> _refreshFavorites() async {
    setState(() {
      _isLoading = true;
      futureTravels = _fetchAllTravels();
    });
    
    await futureTravels;
    await _loadFavorites();
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite(int travelId) async {
    await _favoritesService.toggleFavorite(travelId);
    await _loadFavorites();
    setState(() {}); // Refresh UI
  }

  List<Travel> _getFavoriteTravels(List<Travel> allTravels) {
    return allTravels.where((travel) => _favoriteIds.contains(travel.id)).toList();
  }

  void _navigateToDetail(Travel travel) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TravelDetailScreen(
          travel: travel,
          onTravelUpdated: () {
            _refreshFavorites();
            _loadFavorites();
          },
          onTravelDeleted: () {
            _refreshFavorites();
            _loadFavorites();
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    
    if (result != null) {
      _refreshFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red[400]!,
                    Colors.pink[300]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Дуртай аяллууд',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Travel>>(
        future: futureTravels,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && 
              !_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Алдаа: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshFavorites,
                    child: const Text('Дахин оролдох'),
                  ),
                ],
              ),
            );
          }

          final allTravels = snapshot.data ?? [];
          final favoriteTravels = _getFavoriteTravels(allTravels);

          if (favoriteTravels.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Дуртай аяллын зураг байхгүй байна',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Аяллын зураг дээр дуртай гэж тэмдэглэхэд энд харагдана',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshFavorites,
            child: CustomScrollView(
              slivers: [
                // Header with count
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red[400]!,
                                Colors.pink[300]!,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${favoriteTravels.length} аялал',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Grid
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final travel = favoriteTravels[index];
                        final isFavorite = _favoriteIds.contains(travel.id);
                        return _AnimatedFavoriteCard(
                          travel: travel,
                          index: index,
                          isFavorite: isFavorite,
                          onTap: () => _navigateToDetail(travel),
                          onFavoriteToggle: () => _toggleFavorite(travel.id),
                        );
                      },
                      childCount: favoriteTravels.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Animated Favorite Card Widget with unique design
class _AnimatedFavoriteCard extends StatefulWidget {
  final Travel travel;
  final int index;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const _AnimatedFavoriteCard({
    required this.travel,
    required this.index,
    this.isFavorite = false,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  State<_AnimatedFavoriteCard> createState() => _AnimatedFavoriteCardState();
}

class _AnimatedFavoriteCardState extends State<_AnimatedFavoriteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _heartAnimation;

  @override
  void initState() {
    super.initState();
    
    final delay = widget.index * 0.1;
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _heartAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    Future.delayed(Duration(milliseconds: (delay * 1000).toInt()), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Hero(
            tag: 'travel_image_${widget.travel.id}',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Image
                        Positioned.fill(
                          child: widget.travel.image != null &&
                                  widget.travel.image!.isNotEmpty
                              ? Image.memory(
                                  ImageUtils.decodeBase64Image(
                                      widget.travel.image!)!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                        // Gradient overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Favorite button with unique design
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: () {
                              _controller.reset();
                              _controller.forward();
                              widget.onFavoriteToggle();
                            },
                            child: ScaleTransition(
                              scale: _heartAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  widget.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: widget.isFavorite
                                      ? Colors.red
                                      : Colors.grey[600],
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Content at bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.travel.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        widget.travel.location,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

