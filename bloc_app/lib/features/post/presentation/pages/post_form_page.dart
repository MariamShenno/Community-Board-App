import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/utils.dart';
import 'package:domain/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/di.dart';
import '../blocs/post_form/post_form_bloc.dart';

class PostFormPage extends StatelessWidget {
  const PostFormPage({super.key, this.postId});

  final String? postId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<PostFormBloc>();
        if (postId != null) {
          bloc.add(PostFormPrefilled(postId: postId!));
        }
        return bloc;
      },
      child: PostFormView(isEditMode: postId != null),
    );
  }
}

class PostFormView extends StatefulWidget {
  const PostFormView({super.key, required this.isEditMode});

  final bool isEditMode;

  @override
  State<PostFormView> createState() => _PostFormViewState();
}

class _PostFormViewState extends State<PostFormView>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  File? _selectedImage;
  String? _existingImageUrl;
  bool _imageWasRemoved = false;
  PostDisplay? _originalPost;

  bool _isSaving = false;

  static const Color _pinkPrimary = Color(0xFFE91E63);

  static const Color _dark = Color(0xFF263238);
  static const Color _background = Color(0xFFF3F3F3);
  static const Color _textMuted = Color(0xFF7B8794);

  static const Color _red = Color(0xFFE53935);

  static const LinearGradient _headerGradient = LinearGradient(
    colors: [Color(0xFFE91E63), Color(0xFFD81B60), Color(0xFFC2185B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient _buttonGradient = LinearGradient(
    colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

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
    _titleController.dispose();
    _contentController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
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

  void _submit(PostDisplay? postToEdit) {
    setState(() {
      _autovalidateMode = AutovalidateMode.always;
    });

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (postToEdit != null) {
      context.read<PostFormBloc>().add(
        PostEdited(
          originalPost: postToEdit,
          newTitle: title,
          newContent: content,
          newImageFile: _selectedImage,
          imageWasRemoved: _imageWasRemoved,
        ),
      );
    } else {
      context.read<PostFormBloc>().add(
        PostSubmitted(
          title: title,
          content: content,
          imageFile: _selectedImage,
        ),
      );
    }
  }

  Widget _buildImagePreview() {
    Widget? imageWidget;

    if (_selectedImage != null) {
      imageWidget = Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (_existingImageUrl != null && !_imageWasRemoved) {
      imageWidget = CachedNetworkImage(
        imageUrl: _existingImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            color: _pinkPrimary,
            strokeWidth: 2.5,
          ),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.broken_image_rounded, color: _textMuted, size: 40),
        ),
      );
    }

    if (imageWidget != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: _dark.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF81C784),
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _selectedImage != null
                        ? 'New image selected'
                        : 'Current image',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _imageWasRemoved = true;
                });
              },
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 21,
              ),
              style: IconButton.styleFrom(
                backgroundColor: _red,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _pinkPrimary.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_photo_alternate_rounded,
              size: 38,
              color: _pinkPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Add a post image',
            style: TextStyle(
              color: _dark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Tap here to browse your gallery',
            style: TextStyle(color: _textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: Icon(icon, color: _pinkPrimary, size: 21),
      labelStyle: const TextStyle(color: _textMuted, fontSize: 14),
      floatingLabelStyle: const TextStyle(
        color: _pinkPrimary,
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _dark.withValues(alpha: 0.07)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _pinkPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _red, width: 1.5),
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: _pinkPrimary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: _pinkPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _dark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: _textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostFormBloc, PostFormState>(
      listener: (context, state) {
        if (state is PostFormLoadFailure) {
          showErrorSnackbar(context, message: state.failure.message);

          setState(() {
            _isSaving = false;
          });
        }

        if (state is PostFormLoadSuccess) {
          if (widget.isEditMode && _originalPost == null) {
            _originalPost = state.data;
            _titleController.text = _originalPost!.title;
            _contentController.text = _originalPost!.content;
            _existingImageUrl = _originalPost!.imageUrl;
          } else {
            context.pop();
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is PostFormLoadInProgress;
        final isEditMode = widget.isEditMode;

        return Scaffold(
          backgroundColor: _background,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              decoration: const BoxDecoration(
                gradient: _headerGradient,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: AppBar(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  isEditMode ? 'Edit Post' : 'Create Post',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          body: _isSaving || (isLoading && _originalPost == null)
              ? const Center(
                  child: CircularProgressIndicator(
                    color: _pinkPrimary,
                    strokeWidth: 3,
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _autovalidateMode,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSectionTitle(
                              title: 'Post Image',
                              subtitle: 'Add an attractive image to your post',
                              icon: Icons.image_outlined,
                            ),

                            const SizedBox(height: 14),

                            Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              elevation: 0,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: isLoading ? null : _pickImage,
                                child: Container(
                                  height: 190,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _dark.withValues(alpha: 0.07),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _dark.withValues(alpha: 0.035),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: _buildImagePreview(),
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),
                            _buildSectionTitle(
                              title: 'Post Details',
                              subtitle: 'Write a title and describe your post',
                              icon: Icons.edit_note_rounded,
                            ),

                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _titleController,
                              enabled: !isLoading,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(
                                color: _dark,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: _buildInputDecoration(
                                label: 'Title',
                                icon: Icons.title_rounded,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a title';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _contentController,
                              maxLines: 8,
                              minLines: 5,
                              enabled: !isLoading,
                              keyboardType: TextInputType.multiline,
                              style: const TextStyle(
                                color: _dark,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                              decoration: _buildInputDecoration(
                                label: 'Content',
                                icon: Icons.notes_rounded,
                                alignLabelWithHint: true,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter content.';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: _buttonGradient,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _pinkPrimary.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: isLoading || _isSaving
                                      ? null
                                      : () => _submit(_originalPost),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isEditMode
                                            ? Icons.save_rounded
                                            : Icons.send_rounded,
                                        size: 19,
                                      ),
                                      const SizedBox(width: 9),
                                      Text(
                                        isEditMode
                                            ? 'Update Post'
                                            : 'Publish Post',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 15,
                                  color: _textMuted.withValues(alpha: 0.9),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Make sure your post details are correct',
                                  style: TextStyle(
                                    color: _textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
