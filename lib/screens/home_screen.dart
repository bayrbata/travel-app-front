import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:travelapp/models/travel_model.dart';
import 'package:travelapp/services/api_service.dart';
import 'package:travelapp/services/favorites_service.dart';
import 'package:travelapp/screens/travel_detail_screen.dart';
import 'package:travelapp/screens/add_edit_travel_screen.dart';
import 'package:travelapp/utils/image_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late Future<List<Travel>> futureTravels;
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'created_at';
  String _order = 'DESC';
  String _searchQuery = '';
  bool _isLoading = false;
  final FavoritesService _favoritesService = FavoritesService();
  Set<int> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    futureTravels = _fetchTravels();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _favoritesService.getFavoriteIds();
    setState(() {
      _favoriteIds = favorites;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Travel>> _fetchTravels() async {
    try {
      final travels = await ApiService().fetchTravels(
        sortBy: _sortBy,
        order: _order,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
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

  Future<void> _refreshTravels() async {
    setState(() {
      _isLoading = true;
      futureTravels = _fetchTravels();
    });
    
    await futureTravels;
    
    // Reload favorites to ensure they're in sync
    await _loadFavorites();
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      futureTravels = _fetchTravels();
      // Don't reload favorites - they should persist
    });
  }

  void _onSortChanged(String? sortBy, String? order) {
    if (sortBy != null) _sortBy = sortBy;
    if (order != null) _order = order;
    setState(() {
      futureTravels = _fetchTravels();
      // Don't reload favorites - they should persist
    });
  }

  Future<void> _toggleFavorite(int travelId) async {
    // Optimistically update UI immediately
    setState(() {
      if (_favoriteIds.contains(travelId)) {
        _favoriteIds.remove(travelId);
      } else {
        _favoriteIds.add(travelId);
      }
    });
    
    // Then save to SharedPreferences in background
    // Don't refresh travels list - only update favorites state
    try {
      await _favoritesService.toggleFavorite(travelId);
    } catch (e) {
      // If save fails, revert the optimistic update
      if (mounted) {
        setState(() {
          if (_favoriteIds.contains(travelId)) {
            _favoriteIds.remove(travelId);
          } else {
            _favoriteIds.add(travelId);
          }
        });
      }
    }
  }

  List<Travel> _filterTravels(List<Travel> travels) {
    return travels;
  }

  void _navigateToDetail(Travel travel) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TravelDetailScreen(
          travel: travel,
          onTravelUpdated: () {
            _refreshTravels();
            _loadFavorites();
          },
          onTravelDeleted: () {
            _refreshTravels();
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
      _refreshTravels();
    }
  }

  void _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AddEditTravelScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
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
      _refreshTravels();
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
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.travel_explore,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Travel Gallery',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _navigateToAdd,
              tooltip: 'Шинэ аялал нэмэх',
            ),
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Column(
        children: [
          // Search and Sort Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Хайх (хот, улс, байршил...)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _sortBy,
                          decoration: const InputDecoration(
                            labelText: 'Эрэмбэлэх',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'created_at',
                              child: Text('Огноо'),
                            ),
                            DropdownMenuItem(
                              value: 'travel_date',
                              child: Text('Аяллын огноо'),
                            ),
                            DropdownMenuItem(
                              value: 'title',
                              child: Text('Гарчиг'),
                            ),
                            DropdownMenuItem(
                              value: 'location',
                              child: Text('Байршил'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _onSortChanged(value, null);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _order,
                          decoration: const InputDecoration(
                            labelText: 'Дараалал',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'ASC',
                              child: Text('Өсөх'),
                            ),
                            DropdownMenuItem(
                              value: 'DESC',
                              child: Text('Буурах'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _onSortChanged(null, value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Travel Grid
          Expanded(
            child: FutureBuilder<List<Travel>>(
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
                          onPressed: _refreshTravels,
                          child: const Text('Дахин оролдох'),
                        ),
                      ],
                    ),
                  );
                }

                final allTravels = snapshot.data ?? [];
                final travels = _filterTravels(allTravels);

                if (travels.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.travel_explore,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text('Аяллын зураг олдсонгүй'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _navigateToAdd,
                          icon: const Icon(Icons.add),
                          label: const Text('Шинэ аялал нэмэх'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshTravels,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: travels.length,
                    itemBuilder: (context, index) {
                      final travel = travels[index];
                      final isFavorite = _favoriteIds.contains(travel.id);
                      return _AnimatedTravelCard(
                        travel: travel,
                        index: index,
                        isFavorite: isFavorite,
                        onTap: () => _navigateToDetail(travel),
                        onFavoriteToggle: () => _toggleFavorite(travel.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
          ),
          // Snowflake Animation
          const IgnorePointer(
            child: _SnowflakeAnimation(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAdd,
        icon: const Icon(Icons.add),
        label: const Text('Шинэ аялал'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// Snowflake Animation Widget
class _SnowflakeAnimation extends StatefulWidget {
  const _SnowflakeAnimation();

  @override
  State<_SnowflakeAnimation> createState() => _SnowflakeAnimationState();
}

class _SnowflakeAnimationState extends State<_SnowflakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Snowflake> _snowflakes = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    // Create fewer but larger snowflakes
    for (int i = 0; i < 25; i++) {
      _snowflakes.add(Snowflake(_random));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update snowflake positions
        final screenSize = MediaQuery.of(context).size;
        for (var snowflake in _snowflakes) {
          snowflake.update(screenSize.height);
        }
        
        return CustomPaint(
          painter: SnowflakePainter(snowflakes: _snowflakes),
          size: Size.infinite,
        );
      },
    );
  }
}

class Snowflake {
  late double x;
  late double y;
  late double size;
  late double speed;
  late double opacity;
  late double drift;
  final math.Random _random;

  Snowflake(this._random) {
    x = _random.nextDouble() * 100;
    y = _random.nextDouble() * -100; // Start above screen
    size = 12 + _random.nextDouble() * 25; // Larger snowflakes (12-30)
    speed = 0.3 + _random.nextDouble() * 0.5;
    opacity = 0.6 + _random.nextDouble() * 0.4;
    drift = -0.5 + _random.nextDouble();
  }

  void update(double screenHeight) {
    y += speed;
    x += drift * 0.1; // Horizontal drift
    
    // Reset snowflake if it goes off screen
    if (y > screenHeight + 20) {
      y = -20;
      x = _random.nextDouble() * 100;
    }
    
    // Wrap around horizontally
    if (x < -10) x = 110;
    if (x > 110) x = -10;
  }
}

class SnowflakePainter extends CustomPainter {
  final List<Snowflake> snowflakes;

  SnowflakePainter({required this.snowflakes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (var snowflake in snowflakes) {
      final x = (snowflake.x / 100) * size.width;
      final y = snowflake.y;

      // Use light blue color like in the image
      paint.color = const Color(0xFF87CEEB).withOpacity(snowflake.opacity);
      
      // Draw snowflake (simple 6-pointed star)
      _drawSnowflake(canvas, Offset(x, y), snowflake.size, paint);
    }
  }

  void _drawSnowflake(Canvas canvas, Offset center, double size, Paint paint) {
    // Draw detailed 6-pointed snowflake with branches
    final radius = size * 0.5;
    
    // Main 6 arms
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * math.pi / 180; // Start from top
      
      // Main arm
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);
      
      // Draw main arm
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2.0;
      canvas.drawLine(center, Offset(endX, endY), paint);
      
      // Draw side branches on each arm
      final branchLength = radius * 0.3;
      final branchAngle1 = angle + math.pi / 3; // 60 degrees
      final branchAngle2 = angle - math.pi / 3; // -60 degrees
      
      final branchStartX = center.dx + radius * 0.6 * math.cos(angle);
      final branchStartY = center.dy + radius * 0.6 * math.sin(angle);
      
      // First side branch
      final branch1EndX = branchStartX + branchLength * math.cos(branchAngle1);
      final branch1EndY = branchStartY + branchLength * math.sin(branchAngle1);
      canvas.drawLine(
        Offset(branchStartX, branchStartY),
        Offset(branch1EndX, branch1EndY),
        paint,
      );
      
      // Second side branch
      final branch2EndX = branchStartX + branchLength * math.cos(branchAngle2);
      final branch2EndY = branchStartY + branchLength * math.sin(branchAngle2);
      canvas.drawLine(
        Offset(branchStartX, branchStartY),
        Offset(branch2EndX, branch2EndY),
        paint,
      );
      
      // Small branches at the end of main arm
      final smallBranchLength = radius * 0.15;
      final smallBranch1EndX = endX + smallBranchLength * math.cos(branchAngle1);
      final smallBranch1EndY = endY + smallBranchLength * math.sin(branchAngle1);
      final smallBranch2EndX = endX + smallBranchLength * math.cos(branchAngle2);
      final smallBranch2EndY = endY + smallBranchLength * math.sin(branchAngle2);
      
      canvas.drawLine(
        Offset(endX, endY),
        Offset(smallBranch1EndX, smallBranch1EndY),
        paint,
      );
      canvas.drawLine(
        Offset(endX, endY),
        Offset(smallBranch2EndX, smallBranch2EndY),
        paint,
      );
    }
    
    // Draw center hexagon
    paint.style = PaintingStyle.fill;
    final centerRadius = size * 0.15;
    canvas.drawCircle(center, centerRadius, paint);
    
    // Draw small decorative circles at branch intersections
    paint.style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * math.pi / 180;
      final decorationX = center.dx + radius * 0.6 * math.cos(angle);
      final decorationY = center.dy + radius * 0.6 * math.sin(angle);
      canvas.drawCircle(
        Offset(decorationX, decorationY),
        size * 0.08,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SnowflakePainter oldDelegate) {
    return true;
  }
}

// Staggered Animation Widget
class _AnimatedTravelCard extends StatefulWidget {
  final Travel travel;
  final int index;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const _AnimatedTravelCard({
    required this.travel,
    required this.index,
    this.isFavorite = false,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  State<_AnimatedTravelCard> createState() => _AnimatedTravelCardState();
}

class _AnimatedTravelCardState extends State<_AnimatedTravelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Staggered delay based on index
    final delay = widget.index * 0.1;
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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

    // Start animation with delay
    Future.delayed(Duration(milliseconds: (delay * 1000).toInt()), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(_AnimatedTravelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If favorite status changed, rebuild to show updated icon
    if (oldWidget.isFavorite != widget.isFavorite) {
      setState(() {});
    }
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
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image with Favorite Button
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: widget.travel.image != null &&
                                      widget.travel.image!.isNotEmpty
                                  ? Image.memory(
                                      ImageUtils.decodeBase64Image(
                                          widget.travel.image!)!,
                                      width: double.infinity,
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
                            // Favorite Button
                            Positioned(
                              top: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: () {
                                  widget.onFavoriteToggle();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
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
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Title and location
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.travel.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.travel.location,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.travel.country != null ||
                                widget.travel.city != null) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  if (widget.travel.country != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        widget.travel.country!,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  if (widget.travel.city != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        widget.travel.city!,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
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
      ),
    );
  }
}
