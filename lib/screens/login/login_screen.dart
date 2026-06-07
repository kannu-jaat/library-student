import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../register/register_screen.dart';
import '../pending/pending_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    String mobile = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (mobile.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both Mobile Number and Password')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // Firebase me is mobile number wale user ko dhoondho
      final DatabaseReference ref = FirebaseDatabase.instance.ref("users/$mobile");
      final DataSnapshot snapshot = await ref.get();

      if (snapshot.exists) {
        // User mil gaya, ab password aur status check karo
        Map<dynamic, dynamic> userData = snapshot.value as Map<dynamic, dynamic>;
        
        if (userData['password'] == password) {
          String status = userData['status'] ?? 'pending';

          if (!mounted) return;

          if (status == 'approved') {
            // Login Success! Dashboard par bhejo
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else if (status == 'pending') {
            // Abhi admin ne approve nahi kiya
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PendingScreen()),
            );
          } else {
            // Agar admin ne block ya reject kar diya ho
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Your account is $status. Please contact admin.')),
            );
          }
        } else {
          // Password galat hai
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incorrect Password!')),
            );
          }
        }
      } else {
        // User database me nahi mila
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account not found! Please register first.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.local_library, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'Welcome Back!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              
              TextField(
                controller: _usernameController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 30),
              
              // Login Button ya Loading Spinner
              _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _handleLogin,
                    child: const Text('LOGIN', style: TextStyle(fontSize: 16)),
                  ),
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text('Register Now'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
