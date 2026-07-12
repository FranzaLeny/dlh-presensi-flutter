import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/error_utils.dart';
import '../../../services/auth_service.dart';

class UbahEmailScreen extends StatefulWidget {
  const UbahEmailScreen({super.key});

  @override
  State<UbahEmailScreen> createState() => _UbahEmailScreenState();
}

class _UbahEmailScreenState extends State<UbahEmailScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _isStepOtp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Masukkan alamat email yang valid');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.sendChangeEmailOtp(email);
      if (mounted) {
        setState(() {
          _isStepOtp = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP telah dikirim ke email baru Anda')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(getErrorMessage(e));
      }
    }
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      _showError('Masukkan kode OTP');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.verifyChangeEmailOtp(newEmail: email, otp: otp);
      await AuthService.syncPegawai(); // Refresh data if email is tied to it
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email berhasil diubah')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(getErrorMessage(e));
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Email')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _isStepOtp ? _buildStepOtp() : _buildStepEmail(),
      ),
    );
  }

  Widget _buildStepEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Masukkan alamat email baru. Kami akan mengirimkan kode OTP untuk verifikasi.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Baru',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendOtp,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Kirim Kode OTP'),
        ),
      ],
    );
  }

  Widget _buildStepOtp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Kode OTP telah dikirim ke ${_emailController.text}',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Kode OTP',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verifikasi & Simpan'),
        ),
      ],
    );
  }
}
