import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoritesService {
  static const String _favoritesKey = 'favorite_travel_ids';

  // Get all favorite travel IDs
  Future<Set<int>> getFavoriteIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey);
      
      if (favoritesJson == null || favoritesJson.isEmpty) {
        return <int>{};
      }
      
      final List<dynamic> favoritesList = json.decode(favoritesJson);
      return favoritesList.map((id) => id as int).toSet();
    } catch (e) {
      return <int>{};
    }
  }

  // Check if a travel is favorited
  Future<bool> isFavorite(int travelId) async {
    final favorites = await getFavoriteIds();
    return favorites.contains(travelId);
  }

  // Add a travel to favorites
  Future<bool> addFavorite(int travelId) async {
    try {
      final favorites = await getFavoriteIds();
      favorites.add(travelId);
      
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = json.encode(favorites.toList());
      return await prefs.setString(_favoritesKey, favoritesJson);
    } catch (e) {
      return false;
    }
  }

  // Remove a travel from favorites
  Future<bool> removeFavorite(int travelId) async {
    try {
      final favorites = await getFavoriteIds();
      favorites.remove(travelId);
      
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = json.encode(favorites.toList());
      return await prefs.setString(_favoritesKey, favoritesJson);
    } catch (e) {
      return false;
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(int travelId) async {
    final isFav = await isFavorite(travelId);
    if (isFav) {
      return await removeFavorite(travelId);
    } else {
      return await addFavorite(travelId);
    }
  }

  // Clear all favorites
  Future<bool> clearAllFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_favoritesKey);
    } catch (e) {
      return false;
    }
  }
}

