import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Colors
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF171C35);
  static const Color secondaryTextColor = Color(0xFF73798A);
  static const Color borderColor = Color(0xFFDDE0EA);
  static const Color buttonColor = Color(0xFF171C35);
  static const Color primaryColor = Color(0xFF6C63FF);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // REGISTER
  // ------------------------------------------------------------

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created successfully!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Go back to Login screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
            (route) => false,
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
  // INPUT DECORATION
  // ------------------------------------------------------------

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,

      hintStyle: const TextStyle(
        color: Color(0xFFA4A9B8),
        fontSize: 15,
      ),

      filled: true,
      fillColor: Colors.white,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),

      suffixIcon: suffixIcon,
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: Column(
          children: [
            // ----------------------------------------------------
            // TOP BAR
            // ----------------------------------------------------

            SizedBox(
              height: 53,

              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: textColor,
                    ),

                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),

                  const Text(
                    'Create account',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            const Divider(
              height: 1,
              color: Color(0xFFE1E3EA),
            ),

            // ----------------------------------------------------
            // CONTENT
            // ----------------------------------------------------

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  27,
                  18,
                  25,
                ),

                child: Form(
                  key: _formKey,

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [
                      // ------------------------------------------------
                      // TITLE
                      // ------------------------------------------------

                      const Text(
                        'Get started',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 27,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Store, organize, and find your documents\nin seconds.',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 16,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 29),

                      // ------------------------------------------------
                      // FULL NAME
                      // ------------------------------------------------

                      const Text(
                        'Full name',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 7),

                      TextFormField(
                        controller: _nameController,

                        textCapitalization:
                        TextCapitalization.words,

                        style: const TextStyle(
                          color: textColor,
                          fontSize: 15,
                        ),

                        decoration:
                        _inputDecoration(
                          hintText: 'Rahul Mehta',
                        ),

                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter your name';
                          }

                          if (value.trim().length < 2) {
                            return 'Please enter a valid name';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 19),

                      // ------------------------------------------------
                      // EMAIL
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

                      TextFormField(
                        controller: _emailController,

                        keyboardType:
                        TextInputType.emailAddress,

                        style: const TextStyle(
                          color: textColor,
                          fontSize: 15,
                        ),

                        decoration:
                        _inputDecoration(
                          hintText: 'name@college.edu',
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

                      const SizedBox(height: 19),

                      // ------------------------------------------------
                      // PASSWORD
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

                      TextFormField(
                        controller: _passwordController,

                        obscureText: _obscurePassword,

                        style: const TextStyle(
                          color: textColor,
                          fontSize: 15,
                        ),

                        decoration:
                        _inputDecoration(
                          hintText: '••••••••',

                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons
                                  .visibility_off_outlined
                                  : Icons
                                  .visibility_outlined,

                              color:
                              secondaryTextColor,

                              size: 21,
                            ),

                            onPressed: () {
                              setState(() {
                                _obscurePassword =
                                !_obscurePassword;
                              });
                            },
                          ),
                        ),

                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Please enter a password';
                          }

                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 25),

                      // ------------------------------------------------
                      // CREATE ACCOUNT BUTTON
                      // ------------------------------------------------

                      SizedBox(
                        width: double.infinity,
                        height: 57,

                        child: ElevatedButton(
                          onPressed:
                          _isLoading ? null : _register,

                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            buttonColor,

                            disabledBackgroundColor:
                            buttonColor
                                .withOpacity(0.6),

                            foregroundColor:
                            Colors.white,

                            elevation: 0,

                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                13,
                              ),
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
                            'Create account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}