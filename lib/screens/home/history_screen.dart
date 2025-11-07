import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';
import '../../models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HistoryScreen extends StatefulWidget {
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final supa = Provider.of<SupabaseService>(context, listen: false);
    final userId = supa.currentUserId();
    if (userId == null) {
      setState(() { _loading = false; });
      return;
    }
    final rows = await supa.getHistory(userId);
    setState(() {
      _items = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('History')),
      body: _loading ? Center(child: CircularProgressIndicator()) : _items.isEmpty
          ? Center(child: Text('No history yet'))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, idx) {
                final r = _items[idx];
                return ListTile(
                  leading: r['image_url'] != null && r['image_url'] != '' ? CachedNetworkImage(
                    imageUrl: r['image_url'],
                    width: 56, height: 56, fit: BoxFit.cover,
                    placeholder: (_, __) => CircularProgressIndicator(),
                    errorWidget: (_, __, ___) => Icon(Icons.broken_image),
                  ) : Icon(Icons.image),
                  title: Text(r['predicted_label'] ?? ''),
                  subtitle: Text(r['created_at']?.toString() ?? ''),
                );
              },
            ),
    );
  }
}
