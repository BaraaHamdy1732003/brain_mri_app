import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/input_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/supabase_service.dart';
import '../../routes.dart';

class SignupScreen extends StatefulWidget {
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _signUp() async {
    setState(() { _loading = true; _error = null; });
    final supa = Provider.of<SupabaseService>(context, listen: false);
    try {
      final res = await supa.signUp(_email.text.trim(), _password.text);
      if (res.user != null) {
        Navigator.pushReplacementNamed(context, Routes.home);
      } else {
        setState(() { _error = 'Sign up failed. Check email.'; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign up')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          InputField(controller: _email, label: 'Email'),
          SizedBox(height: 12),
          InputField(controller: _password, label: 'Password', obscure: true),
          SizedBox(height: 16),
          _loading ? CircularProgressIndicator() : CustomButton(label: 'Create account', onPressed: _signUp),
          if (_error != null) Padding(padding: EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Colors.red))),
        ]),
      ),
    );
  }
}
