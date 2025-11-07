import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/model_inference.dart';
import 'services/supabase_service.dart';
import 'routes.dart';
import 'utils/theme.dart';

class BrainMriApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SupabaseService>(create: (_) => SupabaseService()),
        Provider<TFLiteService>(create: (_) => TFLiteService()),
      ],
      child: MaterialApp(
        title: 'Brain MRI App',
        theme: AppTheme.lightTheme,
        initialRoute: Routes.splash,
        routes: Routes.getRoutes(),
      ),
    );
  }
}
