import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/constants.dart';
import 'package:core/utils.dart';
import 'package:domain/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/di.dart';
import '../../../../core/utils/sealed_class_state.dart';
import '../../../post/presentation/blocs/my_post_list/my_post_list_bloc.dart';
import '../../../post/presentation/widgets/my_post_list.dart';
import '../blocs/user_profile/user_profile_bloc.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              getIt<UserProfileBloc>()..add(UserProfileFetched(userId: userId)),
        ),
        BlocProvider(
          create: (context) =>
              getIt<MyPostListBloc>()..add(MyPostListFetched(userId: userId)),
        ),
      ],
      child: BlocListener<MyPostListBloc, MyPostListState>(
        listenWhen: (previous, current) {
          final prevTransientFailure = previous.transientFailure;
          final currentTransientFailure = current.transientFailure;

          return prevTransientFailure == null &&
              currentTransientFailure != null;
        },
        listener: (context, state) {
          showErrorSnackbar(
            context,
            message: state.transientFailure?.message ?? 'Unknown error',
          );

          context.read<MyPostListBloc>().add(
            MyPostListTransientFailureConsumed(),
          );
        },
        child: const UserProfileView(),
      ),
    );
  }
}

class UserProfileView extends StatelessWidget {
  const UserProfileView({super.key});

  static const Color _pinkPrimary = Color(0xFFE91E63);
  static const Color _background = Color(0xFFF3F3F3);
  static const Color _darkText = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _pinkPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: BlocBuilder<UserProfileBloc, UserProfileState>(
          builder: (context, state) {
            final username = state.currentOrPreviousData?.username;

            return Text(
              username ?? 'USER PROFILE',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            );
          },
        ),
      ),
      body: BlocBuilder<UserProfileBloc, UserProfileState>(
        builder: (context, state) {
          return switch (state) {
            UserProfileInitial() ||
            UserProfileLoadInProgress(prevData: null) => const Center(
              child: CircularProgressIndicator(color: _pinkPrimary),
            ),

            UserProfileLoadFailure(failure: final f) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: _pinkPrimary,
                      size: 55,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${f.message}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _darkText, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pinkPrimary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final profile = context
                              .read<UserProfileBloc>()
                              .state
                              .currentOrPreviousData;

                          if (profile != null) {
                            context.read<UserProfileBloc>().add(
                              UserProfileFetched(userId: profile.id),
                            );
                          }
                        },
                        child: const Text(
                          'TRY AGAIN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _ => _ProfileContent(profile: state.currentOrPreviousData!),
          };
        },
      ),
    );
  }
}

class _ProfileContent extends StatefulWidget {
  const _ProfileContent({required this.profile});

  final UserEntity profile;

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent>
    with SingleTickerProviderStateMixin {
  static const Color _pinkPrimary = Color(0xFFE91E63);
  static const Color _darkText = Color(0xFF333333);
  static const Color _lightPink = Color(0xFFFCE4EC);

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
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _pinkPrimary,
      backgroundColor: Colors.white,
      onRefresh: () async {
        context.read<UserProfileBloc>().add(
          UserProfileFetched(userId: widget.profile.id),
        );

        if (widget.profile.role == Roles.admin) {
          context.read<MyPostListBloc>().add(
            MyPostListRefreshed(userId: widget.profile.id),
          );
        }
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 200) {
            if (widget.profile.role == Roles.admin) {
              context.read<MyPostListBloc>().add(
                MyPostListNextPageFetched(userId: widget.profile.id),
              );
            }
          }

          return false;
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header
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
                  Positioned(bottom: 0, child: _buildAvatar()),
                ],
              ),

              const SizedBox(height: 20),

              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      Text(
                        widget.profile.username,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _darkText,
                          letterSpacing: -0.3,
                        ),
                      ),

                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _lightPink, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              size: 15,
                              color: _pinkPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Role: ${widget.profile.role}',
                              style: const TextStyle(
                                color: _pinkPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.profile.role == Roles.admin) ...[
                        const SizedBox(height: 32),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'MY POSTS',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: _darkText,
                                  letterSpacing: 0.5,
                                ),
                              ),

                              BlocBuilder<MyPostListBloc, MyPostListState>(
                                builder: (context, state) {
                                  final count = state.posts.length;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _lightPink,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$count posts',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: _pinkPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: MyPostList(userId: widget.profile.id),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    const double avatarSize = 115;

    return SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: Container(
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
            child:
                widget.profile.avatarUrl == null ||
                    widget.profile.avatarUrl!.isEmpty
                ? const Icon(Icons.person, size: 60, color: Color(0xFFA0AEC0))
                : CachedNetworkImage(
                    imageUrl: widget.profile.avatarUrl!,
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
                    errorWidget: (context, url, error) => const Icon(
                      Icons.person,
                      size: 60,
                      color: Color(0xFFA0AEC0),
                    ),
                  ),
          ),
        ),
      ),
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
