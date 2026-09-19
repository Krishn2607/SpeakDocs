import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthController _authController = AuthController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Colors
  static const Color backgroundColor = Color(0xFF11131F);
  static const Color cardColor = Colors.white;
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color darkButtonColor = Color(0xFF171C35);
  static const Color textColor = Color(0xFF171C35);
  static const Color secondaryTextColor = Color(0xFF73798A);
  static const Color borderColor = Color(0xFFDDE0EA);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // LOGIN
  // ------------------------------------------------------------

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authController.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // FORGOT PASSWORD
  // ------------------------------------------------------------

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    try {
      await _authService.resetPassword(
        _emailController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),

            child: Container(
              width: double.infinity,

              constraints: const BoxConstraints(
                maxWidth: 430,
              ),

              padding: const EdgeInsets.fromLTRB(
                26,
                30,
                26,
                28,
              ),

              decoration: BoxDecoration(
                color: cardColor,

                borderRadius: BorderRadius.circular(34),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.20),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),

              child: Form(
                key: _formKey,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    // ------------------------------------------------
                    // MICROPHONE ICON
                    // ------------------------------------------------

                    Container(
                      width: 64,
                      height: 64,

                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEFF),
                        borderRadius: BorderRadius.circular(18),
                      ),

                      child: const Icon(
                        Icons.mic_none_rounded,
                        size: 34,
                        color: primaryColor,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ------------------------------------------------
                    // TITLE
                    // ------------------------------------------------

                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Log in to search your documents by voice\nor text.',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 16,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ------------------------------------------------
                    // EMAIL LABEL
                    // ------------------------------------------------

                    const Text(
                      'Email',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 7),

                    // ------------------------------------------------
                    // EMAIL FIELD
                    // ------------------------------------------------

                    TextFormField(
                      controller: _emailController,

                      keyboardType:
                      TextInputType.emailAddress,

                      style: const TextStyle(
                        color: textColor,
                        fontSize: 15,
                      ),

                      decoration: InputDecoration(
                        hintText: 'name@college.edu',

                        hintStyle: const TextStyle(
                          color: Color(0xFFA4A9B8),
                          fontSize: 15,
                        ),

                        filled: true,

                        fillColor: Colors.white,

                        contentPadding:
                        const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),

                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(13),

                          borderSide: const BorderSide(
                            color: borderColor,
                          ),
                        ),

                        enabledBorder:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(13),

                          borderSide: const BorderSide(
                            color: borderColor,
                          ),
                        ),

                        focusedBorder:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(13),

                          borderSide:
                          const BorderSide(
                            color: primaryColor,
                            width: 1.5,
                          ),
                        ),
                      ),

                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Please enter your email';
                        }

                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // ------------------------------------------------
                    // PASSWORD LABEL
                    // ------------------------------------------------

                    const Text(
                      'Password',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 7),

                    // ------------------------------------------------
                    // PASSWORD FIELD
                    // ------------------------------------------------

                    TextFormField(
                      controller: _passwordController,

                      obscureText: _obscurePassword,

                      style: const TextStyle(
                        color: textColor,
                        fontSize: 15,
                      ),

                      decoration: InputDecoration(
                        hintText: '••••••••',

                        hintStyle: const TextStyle(
                          color: Color(0xFFA4A9B8),
                        ),

                        filled: true,

                        fillColor: Colors.white,

                        contentPadding:
                        const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),

                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(13),

                          borderSide: const BorderSide(
                            color: borderColor,
                          ),
                        ),

                        enabledBorder:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(13),

                          borderSide: const BorderSide(
                            color: borderColor,
                          ),
                        ),

                        focusedBorder:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(13),

                          borderSide:
                          const BorderSide(
                            color: primaryColor,
                            width: 1.5,
                          ),
                        ),

                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword =
                              !_obscurePassword;
                            });
                          },

                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,

                            color: secondaryTextColor,

                            size: 21,
                          ),
                        ),
                      ),

                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Please enter your password';
                        }

                        return null;
                      },
                    ),

                    // ------------------------------------------------
                    // FORGOT PASSWORD
                    // ------------------------------------------------

                    Align(
                      alignment: Alignment.centerRight,

                      child: TextButton(
                        onPressed: _forgotPassword,

                        style: TextButton.styleFrom(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 8,
                          ),
                        ),

                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ------------------------------------------------
                    // LOGIN BUTTON
                    // ------------------------------------------------

                    SizedBox(
                      width: double.infinity,
                      height: 58,

                      child: ElevatedButton(
                        onPressed:
                        _isLoading ? null : _login,

                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          darkButtonColor,

                          disabledBackgroundColor:
                          darkButtonColor
                              .withOpacity(0.6),

                          foregroundColor: Colors.white,

                          elevation: 0,

                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(13),
                          ),
                        ),

                        child: _isLoading
                            ? const SizedBox(
                          width: 23,
                          height: 23,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 17),

                    // ------------------------------------------------
                    // REGISTER
                    // ------------------------------------------------

                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: secondaryTextColor,
                            fontSize: 15,
                          ),

                          children: [
                            const TextSpan(
                              text:
                              "Don't have an account? ",
                            ),

                            WidgetSpan(
                              alignment:
                              PlaceholderAlignment
                                  .middle,

                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                      const RegisterScreen(),
                                    ),
                                  );
                                },

                                child: const Text(
                                  'Register',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 15,
                                    fontWeight:
                                    FontWeight.w500,
                                  ),
                                ),
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
        ),
      ),
    );
  }
}