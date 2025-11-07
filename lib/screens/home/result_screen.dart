import 'dart:io';
import 'package:flutter/material.dart';
import '../../widgets/prediction_tile.dart';

class ResultScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Map args = ModalRoute.of(context)!.settings.arguments as Map;
    final File imageFile = args['imageFile'];
    final Map result = args['result'];
    final imageUrl = args['imageUrl'] ?? '';

    final List<String> labels = List<String>.from(result['labels'] ?? []);
    final List<double> scores = List<double>.from((result['scores'] as List).map((e) => double.parse(e.toString())));

    final probs = List.generate(labels.length, (i) => {'label': labels[i], 'score': scores[i]});
    probs.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    return Scaffold(
      appBar: AppBar(title: Text('Result')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          Image.file(imageFile, height: 220),
          SizedBox(height: 12),
          Text('Predicted: ${result['predicted_label']}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: probs.length,
              itemBuilder: (_, idx) {
                final p = probs[idx];
                return PredictionTile(label: p['label'], score: p['score']);
              },
            ),
          ),
          if (imageUrl.isNotEmpty) Text('Saved to cloud', style: TextStyle(color: Colors.green)),
        ]),
      ),
    );
  }
}
