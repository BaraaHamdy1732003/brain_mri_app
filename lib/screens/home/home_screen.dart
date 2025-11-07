import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/model_inference.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../routes.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  bool _busy = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pick(ImageSource src) async {
    final picked = await _picker.pickImage(source: src, imageQuality: 85);
    if (picked == null) return;
    setState(() { _image = File(picked.path); });
    await _analyze();
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() { _busy = true; });
    final tflite = Provider.of<TFLiteService>(context, listen: false);
    final supa = Provider.of<SupabaseService>(context, listen: false);

    try {
      final result = await tflite.runModelOnImage(_image!);
      String imageUrl = '';
      try {
        final userId = supa.currentUserId();
        if (userId != null) {
          imageUrl = await supa.uploadPredictionImage(_image!);
          await supa.savePrediction(
            userId: userId,
            imageUrl: imageUrl,
            predictedLabel: result['predicted_label'],
            scores: {
              for (int i = 0; i < (result['labels'] as List).length; i++)
                (result['labels'] as List)[i]: (result['scores'] as List)[i]
            },
          );
        }
      } catch (e) {
        // ignore upload errors
      }
      Navigator.pushNamed(context, Routes.result, arguments: {
        'imageFile': _image,
        'result': result,
        'imageUrl': imageUrl,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Inference error: $e')));
    } finally {
      setState(() { _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final supa = Provider.of<SupabaseService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text('Brain MRI Classifier'),
        actions: [
          IconButton(icon: Icon(Icons.history), onPressed: () => Navigator.pushNamed(context, Routes.history)),
          IconButton(icon: Icon(Icons.logout), onPressed: () async {
            await supa.signOut();
            Navigator.pushReplacementNamed(context, Routes.login);
          }),
        ],
      ),
      body: Center(
        child: _busy ? CircularProgressIndicator() : Padding(
          padding: EdgeInsets.all(16),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            _image == null ? Image.asset('assets/images/logo.png', height: 180) : Image.file(_image!, height: 220),
            SizedBox(height: 16),
            CustomButton(label: 'Pick from gallery', onPressed: () => _pick(ImageSource.gallery)),
            SizedBox(height: 8),
            CustomButton(label: 'Take a picture', onPressed: () => _pick(ImageSource.camera)),
            SizedBox(height: 12),
            Text('Tip: use clear MRI images.'),
          ]),
        ),
      ),
    );
  }
}
