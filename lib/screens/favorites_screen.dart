import 'package:flutter/material.dart';
import 'package:travelapp/models/travel_model.dart';
import 'package:travelapp/services/api_service.dart';
import 'package:travelapp/screens/travel_detail_screen.dart';
import 'package:travelapp/utils/image_utils.dart';

/// =======================
/// 🔥 FAVORITES SERVICE (Singleton)
/// =======================
class FavoritesService extends ChangeNotifier {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final Set<int> _favoriteIds = {};

  Set<int> get favoriteIds => _favoriteIds;

  bool isFavorite(int id) => _favoriteIds.contains(id);

  void toggleFavorite(int id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners(); // 🔥 REALTIME UPDATE
  }
}

/// =======================
/// ⭐ FAVORITES SCREEN
/// =======================
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  late Future<List<Travel>> _futureTravels;

  @override
  void initState() {
    super.initState();
    _futureTravels = ApiService().fetchTravels();
  }

  List<Travel> _favoriteOnly(List<Travel> travels) {
    return travels
        .where((t) => _favoritesService.favoriteIds.contains(t.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _favoritesService,
      builder: (context, _) {
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
          body: FutureBuilder<List<Travel>>(
            future: _futureTravels,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final favorites = _favoriteOnly(snapshot.data!);

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
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// =======================
/// ❤️ FAVORITE CARD
/// =======================
class _FavoriteCard extends StatelessWidget {
  final Travel travel;
  final FavoritesService favoritesService;

  const _FavoriteCard({
    required this.travel,
    required this.favoritesService,
  });

  @override
  Widget build(BuildContext context) {
    final isFavorite = favoritesService.isFavorite(travel.id);

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
                onTap: () => favoritesService.toggleFavorite(travel.id),
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
