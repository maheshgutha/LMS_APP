import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../utils/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isPasswordMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Enter a valid email address');
      return;
    }
    final auth = context.read<AuthProvider>();
    final sent = await auth.sendOtp(email);
    if (sent && mounted) {
      setState(() => _otpSent = true);
      _showSuccess('OTP sent to $email');
    } else if (mounted && auth.error != null) {
      _showError(auth.error!);
    }
  }

  Future<void> _verify() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showError('Enter OTP');
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(email, otp);
    if (!success && mounted && auth.error != null) {
      _showError(auth.error!);
    }
  }

  Future<void> _loginWithPassword() async {
    final email = _emailController.text.trim();
    final pass = _otpController.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _showError('Fill all fields');
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.login(email, pass);
    if (!success && mounted && auth.error != null) {
      _showError(auth.error!);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Logo & Brand
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 16),
                    const Text('AOTMS LMS',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 6),
                    const Text('Learning Management System',
                        style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              const Text('Welcome Back',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              const Text('Sign in to continue learning',
                  style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 24),

              // Email
              const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_otpSent,
                decoration: const InputDecoration(
                  hintText: 'your@email.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Toggle mode
              if (!_otpSent) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _isPasswordMode = !_isPasswordMode),
                      child: Text(_isPasswordMode ? 'Use OTP instead' : 'Use password instead',
                          style: const TextStyle(color: AppTheme.primary, fontSize: 13)),
                    ),
                  ],
                ),
              ],

              if (_otpSent || _isPasswordMode) ...[
                Text(_isPasswordMode ? 'Password' : 'OTP Code',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  keyboardType: _isPasswordMode ? TextInputType.text : TextInputType.number,
                  obscureText: _isPasswordMode,
                  decoration: InputDecoration(
                    hintText: _isPasswordMode ? 'Enter password' : '6-digit OTP',
                    prefixIcon: Icon(_isPasswordMode ? Icons.lock_outline : Icons.pin_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.loading
                        ? null
                        : (_isPasswordMode ? _loginWithPassword : _verify),
                    child: auth.loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(_isPasswordMode ? 'Login' : 'Verify OTP'),
                  ),
                ),
                if (_otpSent) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() {
                        _otpSent = false;
                        _otpController.clear();
                      }),
                      child: const Text('Change Email', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ),
                ],
              ] else ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.loading ? null : _sendOtp,
                    child: auth.loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Send OTP'),
                  ),
                ),
              ],

              const SizedBox(height: 32),
              Center(
                child: Text(
                  'By signing in, you agree to our Terms & Privacy Policy',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
