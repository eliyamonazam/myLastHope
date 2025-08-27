import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String _name = '';
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  void _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await Provider.of<AuthProvider>(context, listen: false)
            .login(_email, _password);
      } else {
        await Provider.of<AuthProvider>(context, listen: false)
            .signup(_name, _email, _password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Signup successful! Please log in.')));
        }
        setState(() => _isLogin = true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An error occurred: ${error.toString()}')));
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_isLogin ? 'Login' : 'Sign Up',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 20),
                if (!_isLogin)
                  TextFormField(
                    key: const ValueKey('name'),
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) =>
                        (value!.isEmpty) ? 'Please enter a name' : null,
                    onSaved: (value) => _name = value!,
                  ),
                TextFormField(
                  key: const ValueKey('email'),
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value!.isEmpty || !value.contains('@'))
                      ? 'Invalid email'
                      : null,
                  onSaved: (value) => _email = value!,
                ),
                TextFormField(
                  key: const ValueKey('password'),
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) => (value!.isEmpty || value.length < 6)
                      ? 'Password is too short'
                      : null,
                  onSaved: (value) => _password = value!,
                ),
                const SizedBox(height: 20),
                if (_isLoading) const CircularProgressIndicator(),
                if (!_isLoading)
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(_isLogin ? 'Login' : 'Sign Up'),
                  ),
                if (!_isLoading)
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin
                        ? 'Create an account'
                        : 'I already have an account'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
