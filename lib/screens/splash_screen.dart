import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../services/model_inference.dart';
import '../routes.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<void> _init() async {
    final sb = Provider.of<SupabaseService>(context, listen: false);
    final tf = Provider.of<TFLiteService>(context, listen: false);
    try {
      await sb.init();
    } catch (e) {
      // ignore
    }
    try {
      await tf.loadModelAndLabels();
    } catch (e) {
      // ignore
    }
    // If user already signed in go to home, else to login
    final userId = sb.currentUserId();
    await Future.delayed(Duration(milliseconds: 800));
    if (userId != null) {
      Navigator.pushReplacementNamed(context, Routes.home);
    } else {
      Navigator.pushReplacementNamed(context, Routes.login);
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
