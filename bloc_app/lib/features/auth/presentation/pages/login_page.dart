import 'package:core/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:string_validator/string_validator.dart' as validator;

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/di/di.dart';
import '../bloc/login/login_bloc.dart';

import 'dart:math' as math;

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<LoginBloc>(),
      child: const LoginView(),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static const Color pink = Color(0xFFE91E63);
  static const Color background = Color(0xFFF3F3F3);

  late final AnimationController _waveController;
  late final AnimationController _contentController;

  late final Animation<double> _contentFadeAnimation;
  late final Animation<Offset> _contentSlideAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _contentFadeAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );

    _contentSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentController,
            curve: Curves.easeOutCubic,
          ),
        );

    _contentController.forward();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _contentController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

    context.read<LoginBloc>().add(
      LoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
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

        appBar: AppBar(
          elevation: 0,
          backgroundColor: pink,
          iconTheme: const IconThemeData(color: Colors.white),
        ),

        body: BlocConsumer<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginLoadFailure) {
              showErrorSnackbar(context, message: state.failure.message);
            }
          },

          builder: (context, state) {
            final isLoading = state is LoginLoadInProgress;

            return Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _LoginWavePainter(
                          color: const Color(0xFFE0E0E0),
                          progress: _waveController.value,
                          baseHeight: 0.52,
                          amplitude: 0.018,
                          phaseOffset: 1.4,
                          frequency: 1.2,
                        ),
                      );
                    },
                  ),
                ),

                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _LoginWavePainter(
                          color: pink,
                          progress: _waveController.value,
                          baseHeight: 0.48,
                          amplitude: 0.022,
                          phaseOffset: 0,
                          frequency: 1.2,
                          showHighlight: true,
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: FadeTransition(
                    opacity: _contentFadeAnimation,
                    child: SlideTransition(
                      position: _contentSlideAnimation,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 24,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Form(
                              key: _formKey,
                              autovalidateMode: _autovalidateMode,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(height: screenHeight * 0.025),
                                  Text(
                                    'WELCOME',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.12,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    'BACK',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.12,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                  ),

                                  const SizedBox(height: 8),

                                  Text(
                                    'Sign in to your Community Board.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),

                                  SizedBox(height: screenHeight * 0.07),
                                  Text(
                                    'SIGN IN',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                  ),

                                  const SizedBox(height: 28),
                                  _buildTextField(
                                    controller: _emailController,
                                    hint: 'Email Address',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter your email.';
                                      }

                                      if (!validator.isEmail(value.trim())) {
                                        return 'Please enter a valid email.';
                                      }

                                      return null;
                                    },
                                    enabled: !isLoading,
                                  ),

                                  const SizedBox(height: 20),
                                  _buildTextField(
                                    controller: _passwordController,
                                    hint: 'Password',
                                    icon: Icons.key_outlined,
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
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
                                    onFieldSubmitted: isLoading
                                        ? null
                                        : (_) => _submit(),
                                    enabled: !isLoading,
                                  ),

                                  const SizedBox(height: 28),
                                  SizedBox(
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: pink,
                                        foregroundColor: Colors.white,
                                        elevation: 3,
                                        shadowColor: pink.withValues(
                                          alpha: 0.3,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'SIGN ME IN',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.7,
                                              ),
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),
                                  TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            context.goNamed(RouteNames.signup);
                                          },
                                    child: const Text(
                                      "Don't have an account? Sign Up",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
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
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    bool enabled = true,
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
        color: Color(0xFF333333),
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

class _LoginWavePainter extends CustomPainter {
  _LoginWavePainter({
    required this.color,
    required this.progress,
    required this.baseHeight,
    required this.amplitude,
    required this.phaseOffset,
    required this.frequency,
    this.showHighlight = false,
  });
  final Color color;
  final double progress;
  final double baseHeight;
  final double amplitude;
  final double phaseOffset;
  final double frequency;
  final bool showHighlight;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = progress * 2 * math.pi + phaseOffset;

    final path = _createWavePath(size, phase);

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, fillPaint);
    if (showHighlight) {
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      final highlightPath = _createWaveLine(size, phase);
      canvas.drawPath(highlightPath, highlightPaint);
    }
  }

  Path _createWavePath(Size size, double phase) {
    final path = Path();

    path.moveTo(0, 0);
    path.lineTo(0, _waveY(0, size, phase));

    const points = 120;

    for (int i = 1; i <= points; i++) {
      final x = size.width * i / points;
      final y = _waveY(x, size, phase);

      path.lineTo(x, y);
    }

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  Path _createWaveLine(Size size, double phase) {
    final path = Path();

    path.moveTo(0, _waveY(0, size, phase));

    const points = 120;

    for (int i = 1; i <= points; i++) {
      final x = size.width * i / points;
      final y = _waveY(x, size, phase);

      path.lineTo(x, y);
    }

    return path;
  }

  double _waveY(double x, Size size, double phase) {
    final normalizedX = x / size.width;

    final primaryWave = math.sin(normalizedX * 2 * math.pi * frequency + phase);

    final secondaryWave = math.sin(
      normalizedX * 2 * math.pi * 2.0 - phase * 0.65,
    );

    final thirdWave = math.sin(normalizedX * 2 * math.pi * 0.7 + phase * 0.4);

    final displacement =
        (primaryWave * 0.65 + secondaryWave * 0.25 + thirdWave * 0.10) *
        amplitude;

    return size.height * (baseHeight + displacement);
  }

  @override
  bool shouldRepaint(covariant _LoginWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.baseHeight != baseHeight ||
        oldDelegate.amplitude != amplitude ||
        oldDelegate.phaseOffset != phaseOffset ||
        oldDelegate.frequency != frequency ||
        oldDelegate.showHighlight != showHighlight;
  }
}
