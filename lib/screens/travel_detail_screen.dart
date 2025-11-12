import 'package:flutter/material.dart';
import 'package:travelapp/models/travel_model.dart';
import 'package:travelapp/services/api_service.dart';
import 'package:travelapp/screens/add_edit_travel_screen.dart';
import 'package:travelapp/utils/image_utils.dart';

class TravelDetailScreen extends StatefulWidget {
  final Travel travel;
  final VoidCallback? onTravelUpdated;
  final VoidCallback? onTravelDeleted;

  const TravelDetailScreen({
    super.key,
    required this.travel,
    this.onTravelUpdated,
    this.onTravelDeleted,
  });

  @override
  State<TravelDetailScreen> createState() => _TravelDetailScreenState();
}

class _TravelDetailScreenState extends State<TravelDetailScreen>
    with SingleTickerProviderStateMixin {
  late Travel _travel;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _travel = widget.travel;
    
    // Fade animation for image
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _deleteTravel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Устгах'),
        content: const Text('Та энэ аяллын зургийг устгахдаа итгэлтэй байна уу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Болих'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Устгах'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await ApiService().deleteTravel(_travel.id);
      if (!mounted) return;
      
      if (widget.onTravelDeleted != null) {
        widget.onTravelDeleted!();
      }
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Амжилттай устгалаа')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Алдаа: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push<Travel>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddEditTravelScreen(travel: _travel),
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

    if (result != null && mounted) {
      setState(() => _travel = result);
      if (widget.onTravelUpdated != null) {
        widget.onTravelUpdated!();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Амжилттай засагдлаа')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Дэлгэрэнгүй'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isLoading ? null : _navigateToEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _deleteTravel,
            color: Colors.red,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with fade animation
                  if (_travel.image != null && _travel.image!.isNotEmpty)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Hero(
                        tag: 'travel_image_${_travel.id}',
                        child: Image.memory(
                          ImageUtils.decodeBase64Image(_travel.image!)!,
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 300,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 100, color: Colors.grey),
                    ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _travel.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_travel.location.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 20, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                _travel.location,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        if (_travel.country != null || _travel.city != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (_travel.country != null)
                                Chip(
                                  label: Text(_travel.country!),
                                  avatar: const Icon(Icons.flag, size: 18),
                                ),
                              if (_travel.city != null) ...[
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(_travel.city!),
                                  avatar: const Icon(Icons.location_city, size: 18),
                                ),
                              ],
                            ],
                          ),
                        ],
                        if (_travel.travelDate != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                _travel.travelDate!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_travel.description != null && _travel.description!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Тайлбар',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _travel.description!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

