import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:newsapp/services/api_service.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key}); // ✅ super.key ашигласан

  @override
  PostScreenState createState() => PostScreenState();
}

class PostScreenState extends State<PostScreen> {
  final _idController = TextEditingController();
  final _typeController = TextEditingController();
  String base64Image = '';
  bool isLoading = false;

  Future<void> pickImage() async {
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
        base64Image = base64Encode(result);
      });
    }
  }

  Future<void> submitNews() async {
    final idText = _idController.text.trim();
    final type = _typeController.text.trim();

    if (idText.isEmpty || type.isEmpty || base64Image.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Бүх талбаруудыг бөглөнө үү')));
      return;
    }

    final id = int.tryParse(idText);
    if (id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ID зөвхөн тоо байх ёстой')));
      return;
    }

    setState(() => isLoading = true);

    try {
      await ApiService().postNews(id, type, base64Image);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Мэдээ амжилттай нэмэгдлээ')),
      );
      _idController.clear();
      _typeController.clear();
      setState(() => base64Image = '');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Алдаа гарлаа: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Шинэ мэдээ нэмэх')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(labelText: 'ID'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(labelText: 'Мэдээний төрөл'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickImage,
              child: const Text('Зураг сонгох'),
            ),
            const SizedBox(height: 10),
            if (base64Image.isNotEmpty)
              Image.memory(base64Decode(base64Image), height: 150),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: submitNews,
                    child: const Text('Нэмэх'),
                  ),
          ],
        ),
      ),
    );
  }
}
