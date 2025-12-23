import 'package:flutter/material.dart';
import 'package:travelapp/models/travel_model.dart';
import 'package:travelapp/services/api_service.dart';
import 'package:travelapp/services/favorites_service.dart';
import 'package:travelapp/screens/travel_detail_screen.dart';
import 'package:travelapp/utils/image_utils.dart';

/// =======================
/// ⭐ FAVORITES SCREEN
/// =======================
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  late Future<List<Travel>> _futureTravels;
  Set<int> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load favorites from SharedPreferences
    final favorites = await _favoritesService.getFavoriteIds();
    setState(() {
      _favoriteIds = favorites;
    });
    
    // Fetch travels
    setState(() {
      _futureTravels = ApiService().fetchTravels();
    });
  }

  // Reload when screen becomes visible
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload favorites when screen is shown
    _favoritesService.getFavoriteIds().then((favorites) {
      if (mounted) {
        setState(() {
          _favoriteIds = favorites;
        });
      }
    });
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  // Public method to refresh from outside
  void refresh() {
    _refreshData();
  }

  List<Travel> _favoriteOnly(List<Travel> travels) {
    return travels
        .where((t) => _favoriteIds.contains(t.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.red, Colors.pink],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Дуртай аяллууд',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<List<Travel>>(
          future: _futureTravels,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
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
                      onPressed: _refreshData,
                      child: const Text('Дахин оролдох'),
                    ),
                  ],
                ),
              );
            }

            final allTravels = snapshot.data ?? [];
            final favorites = _favoriteOnly(allTravels);

            if (favorites.isEmpty) {
              return const Center(
                child: Text(
                  'Дуртай аялал байхгүй байна',
                  style: TextStyle(fontSize: 18),
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                return _FavoriteCard(
                  travel: favorites[index],
                  favoritesService: _favoritesService,
                  onFavoriteChanged: () {
                    // Reload favorites when changed
                    _favoritesService.getFavoriteIds().then((favorites) {
                      if (mounted) {
                        setState(() {
                          _favoriteIds = favorites;
                        });
                      }
                    });
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// =======================
/// ❤️ FAVORITE CARD
/// =======================
class _FavoriteCard extends StatelessWidget {
  final Travel travel;
  final FavoritesService favoritesService;
  final VoidCallback? onFavoriteChanged;

  const _FavoriteCard({
    required this.travel,
    required this.favoritesService,
    this.onFavoriteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: favoritesService.isFavorite(travel.id),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;
        
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TravelDetailScreen(
                  travel: travel,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // 🖼 IMAGE
                Positioned.fill(
                  child: travel.image != null && travel.image!.isNotEmpty
                      ? Image.memory(
                          ImageUtils.decodeBase64Image(travel.image!)!,
                          fit: BoxFit.cover,
                        )
                      : Container(color: Colors.grey[300]),
                ),

                // ❤️ HEART
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () async {
                      await favoritesService.toggleFavorite(travel.id);
                      if (onFavoriteChanged != null) {
                        onFavoriteChanged!();
                      }
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),

            // 🌫 GRADIENT + TITLE
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                ),
                child: Text(
                  travel.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
