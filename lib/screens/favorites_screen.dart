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
  int _currentPage = 0;
  bool _isLoading = false;

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

            final favorites = _favoriteOnly(snapshot.data ?? []);

            if (favorites.isEmpty) {
              return const Center(
                child: Text(
                  'Дуртай аялал байхгүй',
                  style: TextStyle(fontSize: 18),
                ),
              );
            }

            return Column(
              children: [
                const SizedBox(height: 20),
                // PageView with travel cards
                Expanded(
                  child: Stack(
                    children: [
                      PageView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: favorites.length,
                        onPageChanged: (index) async {
                          setState(() => _isLoading = true);
                          await Future.delayed(const Duration(milliseconds: 300));
                          setState(() {
                            _currentPage = index;
                            _isLoading = false;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: _FavoriteCard(
                              travel: favorites[index],
                              favoritesService: _favoritesService,
                              onFavoriteChanged: _loadData,
                            ),
                          );
                        },
                      ),
                      // Loading overlay
                      if (_isLoading)
                        Center(
                          child: Container(
                            color: Colors.black45,
                            child: const CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
                // Page indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    favorites.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                      width: _currentPage == index ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.deepPurple
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
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

        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TravelDetailScreen(travel: travel),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// 🖼 IMAGE
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        travel.image != null && travel.image!.isNotEmpty
                            ? Image.memory(
                                ImageUtils.decodeBase64Image(travel.image!)!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                ),
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
                      ],
                    ),
                  ),
                ),
                /// 📝 TITLE & DESCRIPTION
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        travel.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (travel.description != null &&
                          travel.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SelectableText(
                          travel.description!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (travel.location.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: SelectableText(
                                travel.location,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
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
        );
      },
    );
  }
}
