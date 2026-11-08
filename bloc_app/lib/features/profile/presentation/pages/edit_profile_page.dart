import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/di.dart';
import '../../../../core/utils/sealed_class_state.dart';
import '../blocs/edit_profile/edit_profile_bloc.dart';
import '../blocs/profile/profile_bloc.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<EditProfileBloc>(),
      child: const EditProfileView(),
    );
  }
}

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  final _usernameController = TextEditingController();

  File? _selectedImage;
  String? _existingImageUrl;
  bool _imageWasRemoved = false;

  static const Color _pinkPrimary = Color(0xFFE91E63);
  static const Color _background = Color(0xFFF3F3F3);
  static const Color _darkText = Color(0xFF333333);
  static const Color _subtleText = Color(0xFF8A94A6);
  static const Color _dangerColor = Color(0xFFE53935);

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    final profile = context.read<ProfileBloc>().state.currentOrPreviousData;

    if (profile != null) {
      _usernameController.text = profile.username;
      _existingImageUrl = profile.avatarUrl;
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();

    try {
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageWasRemoved = false;
        });
      }
    } on PlatformException catch (e) {
      debugPrint('Failed to pick image: $e');
    } catch (e) {
      debugPrint('Unexpected error occurred: $e');

      if (!mounted) return;

      showErrorSnackbar(context, message: e.toString());
    }
  }

  void _submit() {
    setState(() {
      _autovalidateMode = AutovalidateMode.always;
    });

    final form = _formKey.currentState;

    if (form == null || !form.validate()) return;

    FocusScope.of(context).unfocus();

    final profile = context.read<ProfileBloc>().state.currentOrPreviousData!;

    context.read<EditProfileBloc>().add(
      EditProfileSubmitted(
        userId: profile.id,
        originalAvatarUrl: profile.avatarUrl,
        username: _usernameController.text.trim(),
        newAvatarFile: _selectedImage,
        avatarWasRemoved: _imageWasRemoved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditProfileBloc, EditProfileState>(
      listener: (context, state) {
        if (state is EditProfileLoadFailure) {
          showErrorSnackbar(context, message: state.failure.message);
        }

        if (state is EditProfileLoadSuccess) {
          context.read<ProfileBloc>().add(MyProfileFetched());

          if (context.canPop()) {
            context.pop();
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is EditProfileLoadInProgress;

        return Scaffold(
          backgroundColor: _background,
          appBar: AppBar(
            backgroundColor: _pinkPrimary,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: const Text(
              'EDIT PROFILE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    ClipPath(
                      clipper: HeaderCurvedClipper(),
                      child: Container(
                        width: double.infinity,
                        height: 210,
                        color: _pinkPrimary,
                      ),
                    ),
                    Positioned(bottom: 0, child: _buildAvatarWithGlow()),
                  ],
                ),

                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _autovalidateMode,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton.icon(
                                  onPressed: isLoading ? null : _pickImage,
                                  icon: const Icon(
                                    Icons.image_outlined,
                                    size: 18,
                                    color: _pinkPrimary,
                                  ),
                                  label: const Text(
                                    'Change Photo',
                                    style: TextStyle(
                                      color: _pinkPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  height: 18,
                                  width: 1,
                                  color: Colors.black12,
                                ),
                                const SizedBox(width: 12),
                                TextButton.icon(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _selectedImage = null;
                                            _imageWasRemoved = true;
                                          });
                                        },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: _dangerColor,
                                  ),
                                  label: const Text(
                                    'Remove',
                                    style: TextStyle(
                                      color: _dangerColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),
                            _buildInputField(
                              label: 'USERNAME',
                              controller: _usernameController,
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: _pinkPrimary,
                                size: 22,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter username';
                                }

                                if (val.trim().length < 2) {
                                  return 'Username must be at least 2 characters';
                                }

                                if (val.trim().length > 20) {
                                  return 'Username must not exceed 20 characters';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 36),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _pinkPrimary,
                                  disabledBackgroundColor: _pinkPrimary
                                      .withValues(alpha: 0.6),
                                  elevation: 3,
                                  shadowColor: _pinkPrimary.withValues(
                                    alpha: 0.3,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: isLoading ? null : _submit,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'SAVE CHANGES',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarWithGlow() {
    const double avatarSize = 115;

    Widget imageWidget;

    if (_selectedImage != null) {
      imageWidget = Image.file(_selectedImage!, fit: BoxFit.cover);
    } else if (_existingImageUrl != null && !_imageWasRemoved) {
      imageWidget = CachedNetworkImage(
        imageUrl: _existingImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _pinkPrimary,
            ),
          ),
        ),
        errorWidget: (context, url, error) =>
            const Icon(Icons.person, size: 60, color: Color(0xFFA0AEC0)),
      );
    } else {
      imageWidget = const Icon(
        Icons.person,
        size: 60,
        color: Color(0xFFA0AEC0),
      );
    }

    return SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: Container(
                color: const Color(0xFFE2E8F0),
                child: imageWidget,
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _pinkPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: _darkText,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(
              color: _darkText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              hintStyle: const TextStyle(color: _subtleText, fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _pinkPrimary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _dangerColor, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _dangerColor, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HeaderCurvedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height - 40);

    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 40,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
