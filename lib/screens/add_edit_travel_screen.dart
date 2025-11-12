import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:travelapp/models/travel_model.dart';
import 'package:travelapp/services/api_service.dart';
import 'package:travelapp/utils/image_utils.dart';

class AddEditTravelScreen extends StatefulWidget {
  final Travel? travel;

  const AddEditTravelScreen({super.key, this.travel});

  @override
  State<AddEditTravelScreen> createState() => _AddEditTravelScreenState();
}

class _AddEditTravelScreenState extends State<AddEditTravelScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _travelDateController = TextEditingController();
  
  String? _base64Image;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Scale animation for image preview
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    if (widget.travel != null) {
      _titleController.text = widget.travel!.title;
      _descriptionController.text = widget.travel!.description ?? '';
      _locationController.text = widget.travel!.location;
      _countryController.text = widget.travel!.country ?? '';
      _cityController.text = widget.travel!.city ?? '';
      _travelDateController.text = widget.travel!.travelDate ?? '';
      _base64Image = widget.travel!.image;
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _travelDateController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      Uint8List imageBytes = await pickedFile.readAsBytes();
      var result = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 800,
        minHeight: 600,
        quality: 88,
      );
      
      if (!mounted) return;
      setState(() {
        _base64Image = base64Encode(result);
      });
      _animationController.forward(from: 0.0);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() {
        _travelDateController.text = 
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_titleController.text.trim().isEmpty || 
        _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Гарчиг болон байршил заавал шаардлагатай')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Travel result;
      
      if (widget.travel != null) {
        // Update existing travel
        result = await ApiService().updateTravel(
          id: widget.travel!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          country: _countryController.text.trim().isEmpty 
              ? null 
              : _countryController.text.trim(),
          city: _cityController.text.trim().isEmpty 
              ? null 
              : _cityController.text.trim(),
          imageBase64: _base64Image,
          travelDate: _travelDateController.text.trim().isEmpty 
              ? null 
              : _travelDateController.text.trim(),
        );
      } else {
        // Create new travel
        result = await ApiService().createTravel(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          country: _countryController.text.trim().isEmpty 
              ? null 
              : _countryController.text.trim(),
          city: _cityController.text.trim().isEmpty 
              ? null 
              : _cityController.text.trim(),
          imageBase64: _base64Image,
          travelDate: _travelDateController.text.trim().isEmpty 
              ? null 
              : _travelDateController.text.trim(),
        );
      }

      if (!mounted) return;
      
      Navigator.pop(context, result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.travel != null 
              ? 'Амжилттай засагдлаа' 
              : 'Амжилттай нэмэгдлээ'),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.travel != null ? 'Засварлах' : 'Шинэ аялал нэмэх'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Гарчиг *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Гарчиг оруулна уу';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Байршил *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Байршил оруулна уу';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Улс',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Хот',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _travelDateController,
                decoration: const InputDecoration(
                  labelText: 'Аяллын огноо',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Тайлбар',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Зураг сонгох'),
              ),
              const SizedBox(height: 16),
              if (_base64Image != null && _base64Image!.isNotEmpty)
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        ImageUtils.decodeBase64Image(_base64Image!)!,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                      ),
                      child: Text(widget.travel != null ? 'Хадгалах' : 'Нэмэх'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

