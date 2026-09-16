import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/responsive.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();
    final success =
        await authProvider.sendPasswordResetEmail(_emailController.text.trim());

    if (!mounted) return;

    if (success) {
      setState(() {
        _emailSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Password reset email sent!')),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(authProvider.error ?? 'Failed to send email'),
              ),
            ],
          ),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        // ✅ STATIC GRADIENT - NO ANIMATION
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF16213E),
                    const Color(0xFF0F3460),
                    const Color(0xFF1A1A2E),
                  ]
                : [
                    const Color(0xFF764ba2),
                    const Color(0xFF667eea),
                    const Color(0xFFf093fb),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(Responsive.wp(context, 6)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon & Title
                        FadeInDown(
                          duration: const Duration(milliseconds: 500),
                          child: Column(
                            children: [
                              Container(
                                width: Responsive.wp(context, 25),
                                height: Responsive.wp(context, 25),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                child: Icon(
                                  _emailSent
                                      ? Icons.mark_email_read
                                      : Icons.lock_reset,
                                  size: Responsive.sp(context, 48),
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: Responsive.hp(context, 3)),
                              Text(
                                _emailSent
                                    ? 'Check Your Email'
                                    : 'Forgot Password?',
                                style: TextStyle(
                                  fontSize: Responsive.sp(context, 28),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: Responsive.hp(context, 1)),
                              Text(
                                _emailSent
                                    ? 'We\'ve sent a password reset link to your email'
                                    : 'Enter your email to receive a password reset link',
                                style: TextStyle(
                                  fontSize: Responsive.sp(context, 14),
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: Responsive.hp(context, 5)),

                        // Form Card
                        if (!_emailSent)
                          FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            child: Container(
                              padding:
                                  EdgeInsets.all(Responsive.wp(context, 6)),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // Email Field
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: Responsive.sp(context, 15),
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        hintText: 'Enter your email',
                                        prefixIcon: Icon(
                                          Icons.email_outlined,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.grey.shade600,
                                        ),
                                        labelStyle: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.grey.shade700,
                                        ),
                                        hintStyle: TextStyle(
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.grey.shade400,
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? Colors.white.withValues(alpha: 0.05)
                                            : Colors.grey.shade100,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? Colors.white10
                                                : Colors.grey.shade300,
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: AppTheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: AppTheme.danger,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: Responsive.hp(context, 3)),

                                    // Send Button
                                    Consumer<AuthProvider>(
                                      builder: (context, authProvider, _) {
                                        return SizedBox(
                                          width: double.infinity,
                                          height: 56,
                                          child: ElevatedButton(
                                            onPressed: authProvider.isLoading
                                                ? null
                                                : _sendResetEmail,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primary,
                                              foregroundColor: Colors.white,
                                              elevation: 8,
                                              shadowColor: AppTheme.primary
                                                  .withValues(alpha: 0.5),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: authProvider.isLoading
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                                  Color>(
                                                              Colors.white),
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'Send Reset Link',
                                                        style: TextStyle(
                                                          fontSize:
                                                              Responsive.sp(
                                                                  context, 16),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          letterSpacing: 1,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Icon(Icons.send),
                                                    ],
                                                  ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Success Card
                        if (_emailSent)
                          FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            child: Container(
                              padding:
                                  EdgeInsets.all(Responsive.wp(context, 6)),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: Responsive.sp(context, 64),
                                    color: AppTheme.success,
                                  ),
                                  SizedBox(height: Responsive.hp(context, 2)),
                                  Text(
                                    'Email sent successfully!',
                                    style: TextStyle(
                                      fontSize: Responsive.sp(context, 18),
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: Responsive.hp(context, 1)),
                                  Text(
                                    'Please check your email and click the reset link to create a new password.',
                                    style: TextStyle(
                                      fontSize: Responsive.sp(context, 14),
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.grey.shade700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: Responsive.hp(context, 3)),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text('Back to Login'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
