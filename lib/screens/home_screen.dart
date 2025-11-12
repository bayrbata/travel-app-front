import 'package:flutter/material.dart';
import 'package:travelapp/models/travel_model.dart';
import 'package:travelapp/services/api_service.dart';
import 'package:travelapp/screens/travel_detail_screen.dart';
import 'package:travelapp/screens/add_edit_travel_screen.dart';
import 'package:travelapp/utils/image_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Travel>> futureTravels;
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'created_at';
  String _order = 'DESC';
  String _searchQuery = '';
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    futureTravels = _fetchTravels();
    
    // Fade animation for list items
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
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
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      futureTravels = _fetchTravels();
    });
  }

  void _onSortChanged(String? sortBy, String? order) {
    if (sortBy != null) _sortBy = sortBy;
    if (order != null) _order = order;
    setState(() {
      futureTravels = _fetchTravels();
    });
  }

  void _navigateToDetail(Travel travel) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TravelDetailScreen(
          travel: travel,
          onTravelUpdated: _refreshTravels,
          onTravelDeleted: _refreshTravels,
        ),
      ),
    );
    
    if (result != null) {
      _refreshTravels();
    }
  }

  void _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditTravelScreen(),
      ),
    );
    
    if (result != null) {
      _refreshTravels();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAdd,
            tooltip: 'Шинэ аялал нэмэх',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Sort Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        decoration: const InputDecoration(
                          labelText: 'Эрэмбэлэх',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _order,
                        decoration: const InputDecoration(
                          labelText: 'Дараалал',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
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

                final travels = snapshot.data ?? [];

                if (travels.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.travel_explore, size: 64, color: Colors.grey),
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
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: travels.length,
                      itemBuilder: (context, index) {
                        final travel = travels[index];
                        return _buildTravelCard(travel, index);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTravelCard(Travel travel, int index) {
    return Hero(
      tag: 'travel_image_${travel.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDetail(travel),
          borderRadius: BorderRadius.circular(12),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with fade animation
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: travel.image != null && travel.image!.isNotEmpty
                        ? Image.memory(
                            ImageUtils.decodeBase64Image(travel.image!)!,
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
                ),
                // Title and location
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        travel.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              travel.location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (travel.country != null || travel.city != null) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: [
                            if (travel.country != null)
                              Chip(
                                label: Text(
                                  travel.country!,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            if (travel.city != null)
                              Chip(
                                label: Text(
                                  travel.city!,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
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
    );
  }
}
