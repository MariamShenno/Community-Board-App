import 'package:core/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:string_validator/string_validator.dart' as validator;
import '../../../../core/config/router/route_constants.dart';
import '../../../../core/di/di.dart';
import '../bloc/signup/signup_bloc.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SignupBloc>(),
      child: const SignupView(),
    );
  }
}

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormState>();

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  static const Color pink = Color(0xFFE91E63);
  static const Color background = Color(0xFFF3F3F3);
  static const Color darkText = Color(0xFF333333);

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      setState(() {
        _autovalidateMode = AutovalidateMode.always;
      });
      return;
    }

    context.read<SignupBloc>().add(
      SignupRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: background,
        body: BlocConsumer<SignupBloc, SignupState>(
          listener: (context, state) {
            if (state is SignupLoadFailure) {
              showErrorSnackbar(context, message: state.failure.message);
            }
          },

          builder: (context, state) {
            final isLoading = state is SignupLoadInProgress;

            return Stack(
              children: [
                Positioned.fill(child: Container(color: pink)),
                Positioned.fill(
                  child: ClipPath(
                    clipper: _SignupShapeClipper2(),
                    child: Container(color: Colors.white),
                  ),
                ),

                Positioned.fill(
                  child: ClipPath(
                    clipper: _SignupShapeClipper1(),
                    child: Container(color: background),
                  ),
                ),

                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 20,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: _autovalidateMode,

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: screenHeight * 0.12),

                              Text(
                                'SIGN UP',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: darkText,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),

                              const SizedBox(height: 8),

                              const Text(
                                'Create your account and join us.',
                                style: TextStyle(
                                  color: pink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 28),

                              _buildTextField(
                                controller: _usernameController,
                                hint: 'User name',
                                icon: Icons.person_outline,
                                enabled: !isLoading,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter username.';
                                  }

                                  if (value.trim().length < 2) {
                                    return 'Please enter at least 2 characters.';
                                  }

                                  if (value.trim().length > 20) {
                                    return 'Username must not exceed 20 characters.';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              _buildTextField(
                                controller: _emailController,
                                hint: 'Email',
                                icon: Icons.email_outlined,
                                enabled: !isLoading,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email.';
                                  }

                                  if (!validator.isEmail(value.trim())) {
                                    return 'Please enter a valid email.';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: _passwordController,
                                hint: 'Password',
                                icon: Icons.key_outlined,
                                enabled: !isLoading,
                                obscureText: true,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter password.';
                                  }

                                  if (value.trim().length < 6) {
                                    return 'Password must be at least 6 characters.';
                                  }

                                  if (value.trim().length > 20) {
                                    return 'Password must not exceed 20 characters.';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: _confirmPasswordController,
                                hint: 'Confirm Password',
                                icon: Icons.lock_outline,
                                enabled: !isLoading,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: isLoading
                                    ? null
                                    : (_) => _submit(),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your confirmation password.';
                                  }

                                  if (value != _passwordController.text) {
                                    return 'The password does not match.';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 28),
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: darkText,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'SIGN ME UP',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 20),
                              Transform.translate(
                                offset: const Offset(-12, 0),
                                child: TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          context.goNamed(RouteNames.login);
                                        },
                                  child: const Text(
                                    'Already have an account? Login',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: darkText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      enabled: enabled,
      onFieldSubmitted: onFieldSubmitted,

      style: const TextStyle(
        color: darkText,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),

      cursorColor: pink,

      decoration: InputDecoration(
        hintText: hint,

        hintStyle: const TextStyle(
          color: Color(0xFF777777),
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),

        prefixIcon: Icon(icon, color: pink, size: 22),

        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.2),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: pink, width: 2),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}

class _SignupShapeClipper1 extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height * 0.48);

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.43,
      size.width * 0.5,
      size.height * 0.47,
    );

    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.52,
      size.width,
      size.height * 0.45,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

class _SignupShapeClipper2 extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height * 0.53);

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.48,
      size.width * 0.5,
      size.height * 0.52,
    );

    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.57,
      size.width,
      size.height * 0.50,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
