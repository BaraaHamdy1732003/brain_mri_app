import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';

class SupabaseService {
  bool _initialized = false;
  SupabaseClient get client => Supabase.instance.client;

  Future<void> init() async {
    if (_initialized) return;
    await Supabase.initialize(
      url: SUPABASE_URL,
      anonKey: SUPABASE_ANON_KEY,
    );
    _initialized = true;
  }

  Future<void> signOut() async {
    await init();
    await client.auth.signOut();
  }

  Future<AuthResponse> signIn(String email, String password) async {
    await init();
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password) async {
    await init();
    return await client.auth.signUp(email: email, password: password);
  }

  String? currentUserId() {
    return client.auth.currentUser?.id;
  }

  Future<String> uploadPredictionImage(File file) async {
    await init();
    final bucket = 'predictions';
    final id = Uuid().v4();
    final path = '$id.jpg';
    // ensure bucket exists in Supabase dashboard
    await client.storage.from(bucket).uploadBinary(path, await file.readAsBytes(), fileOptions: FileOptions(contentType: 'image/jpeg'));
    final publicUrl = client.storage.from(bucket).getPublicUrl(path);
    return publicUrl;
  }

  Future<void> savePrediction({
    required String userId,
    required String imageUrl,
    required String predictedLabel,
    required Map<String, dynamic> scores,
  }) async {
    await init();
    await client.from('predictions').insert({
      'user_id': userId,
      'image_url': imageUrl,
      'predicted_label': predictedLabel,
      'scores': scores,
    });
  }

  Future<List<Map<String, dynamic>>> getHistory(String userId) async {
    await init();
    final res = await client
        .from('predictions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }
}
