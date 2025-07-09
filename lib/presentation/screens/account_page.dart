
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _isRegistering = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _performAuthAction() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isRegistering) {
        await _supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          data: {'username': _usernameController.text.trim()},
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registrazione avvenuta con successo!')),
          );
          setState(() {
            _isRegistering = false; // Switch back to login view after successful registration
          });
        }
      } else {
        await _supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      if (mounted) {
        _emailController.clear();
        _passwordController.clear();
        _usernameController.clear();
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: ${e.message}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: ${e.message}')),
        );
      }
    } finally {
       if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegistering ? 'Registrazione' : 'Login'),
      ),
      body: StreamBuilder<AuthState>(
        stream: _supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.session != null) {
            final user = snapshot.data!.session!.user;
            return _buildProfileView(user);
          }
          return _buildAuthForm();
        },
      ),
    );
  }

  Widget _buildProfileView(User user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 20),
            Text(
              user.userMetadata?['username'] ?? 'Nessun username',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              user.email ?? 'Nessuna email',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            CupertinoButton.filled(
              onPressed: _isLoading ? null : _signOut,
              child: _isLoading
                  ? const CupertinoActivityIndicator()
                  : const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthForm() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Login'),
                const SizedBox(width: 10),
                CupertinoSwitch(
                  value: _isRegistering,
                  onChanged: (value) {
                    setState(() {
                      _isRegistering = value;
                    });
                  },
                ),
                const SizedBox(width: 10),
                const Text('Registrati'),
              ],
            ),
            const SizedBox(height: 30),
            if (_isRegistering)
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (_isRegistering && (value == null || value.isEmpty)) {
                    return 'Inserisci un username';
                  }
                  return null;
                },
              ),
            if (_isRegistering) const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci la tua email';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci la tua password';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),
            if (_isLoading)
              const CupertinoActivityIndicator()
            else
              CupertinoButton.filled(
                onPressed: _performAuthAction,
                child: Text(_isRegistering ? 'Registrati' : 'Login'),
              ),
          ],
        ),
      ),
    );
  }
}
