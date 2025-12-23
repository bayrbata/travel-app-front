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
  FavoritesScreenState createState() => FavoritesScreenState();
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
    // Load favorites first
    final favorites = await _favoritesService.getFavoriteIds();
    setState(() {
      _favoriteIds = favorites;
      // Only refresh travels if needed, don't reset favorites
      _futureTravels = ApiService().fetchTravels();
    });
  }

  Future<void> refreshData() async {
    await _loadData();
  }

  List<Travel> _favoriteOnly(List<Travel> travels) {
    return travels.where((t) => _favoriteIds.contains(t.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Дуртай аяллууд',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: FutureBuilder<List<Travel>>(
          future: _futureTravels,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Алдаа: ${snapshot.error}'));
            }

            final favorites =
                _favoriteOnly(snapshot.data ?? []);

            if (favorites.isEmpty) {
              return const Center(
                child: Text(
                  'Дуртай аялал байхгүй',
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
                  onFavoriteChanged: _loadData,
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
  final VoidCallback onFavoriteChanged;

  const _FavoriteCard({
    required this.travel,
    required this.favoritesService,
    required this.onFavoriteChanged,
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
                builder: (_) => TravelDetailScreen(travel: travel),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                /// 🖼 IMAGE
                Positioned.fill(
                  child: travel.image != null && travel.image!.isNotEmpty
                      ? Image.memory(
                          ImageUtils.decodeBase64Image(travel.image!)!,
                          fit: BoxFit.cover,
                        )
                      : Container(color: Colors.grey[300]),
                ),

                /// ❤️ FAVORITE ICON
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () async {
                      // Toggle favorite without causing full refresh
                      await favoritesService.toggleFavorite(travel.id);
                      // Only reload data to update the list
                      onFavoriteChanged();
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),

                /// 🌫 TITLE GRADIENT
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
                          Colors.black.withOpacity(0.7),
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
      },
    );
  }
}
