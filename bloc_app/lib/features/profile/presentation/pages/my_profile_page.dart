import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/constants.dart';
import 'package:core/utils.dart';
import 'package:domain/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router/route_constants.dart';
import '../../../../core/di/di.dart';
import '../../../../core/utils/sealed_class_state.dart';
import '../../../auth/presentation/bloc/authentication/authentication_bloc.dart';
import '../../../post/presentation/blocs/my_post_list/my_post_list_bloc.dart';
import '../../../post/presentation/widgets/my_post_list.dart';
import '../blocs/profile/profile_bloc.dart';

class MyProfilePage extends StatelessWidget {
  const MyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.select(
      (AuthenticationBloc bloc) => bloc.state.user?.id,
    );

    if (userId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F3F3),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE91E63)),
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<ProfileBloc>()..add(MyProfileFetched()),
        ),
        BlocProvider(
          create: (context) =>
              getIt<MyPostListBloc>()..add(MyPostListFetched(userId: userId)),
        ),
      ],
      child: const MyProfileView(),
    );
  }
}

class MyProfileView extends StatelessWidget {
  const MyProfileView({super.key});

  static const Color pink = Color(0xFFE91E63);
  static const Color background = Color(0xFFF3F3F3);
  static const Color darkText = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return BlocListener<MyPostListBloc, MyPostListState>(
      listenWhen: (previous, current) {
        final prevTransientFailure = previous.transientFailure;
        final currentTransientFailure = current.transientFailure;

        return prevTransientFailure == null && currentTransientFailure != null;
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
      child: Scaffold(
        backgroundColor: background,

        appBar: AppBar(
          backgroundColor: pink,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: const Text(
            'MY PROFILE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 1,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              tooltip: 'Edit Profile',
              onPressed: () {
                context.pushNamed(
                  RouteNames.profileEdit,
                  extra: context.read<ProfileBloc>(),
                );
              },
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
            ),
            IconButton(
              tooltip: 'Logout',
              onPressed: () {
                context.read<AuthenticationBloc>().add(
                  AuthenticationLogoutRequested(),
                );
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
            ),
          ],
        ),

        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            return switch (state) {
              ProfileInitial() || ProfileLoadInProgress(prevData: null) =>
                const Center(child: CircularProgressIndicator(color: pink)),

              ProfileLoadFailure(:final failure, prevData: null) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 55, color: pink),
                      const SizedBox(height: 16),
                      Text(
                        failure.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: darkText, fontSize: 15),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pink,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          context.read<ProfileBloc>().add(MyProfileFetched());
                        },
                        child: const Text(
                          'TRY AGAIN',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
        floatingActionButton:
            BlocBuilder<AuthenticationBloc, AuthenticationState>(
              builder: (context, state) {
                if (state.user?.role == Roles.admin) {
                  return FloatingActionButton(
                    heroTag: null,
                    backgroundColor: pink,
                    elevation: 4,
                    onPressed: () {
                      context.push(RoutePaths.postCreate);
                    },
                    tooltip: 'Create Post',
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
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
  static const Color pink = Color(0xFFE91E63);
  static const Color background = Color(0xFFF3F3F3);
  static const Color darkText = Color(0xFF333333);

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
      color: pink,
      backgroundColor: Colors.white,
      onRefresh: () async {
        context.read<ProfileBloc>().add(MyProfileFetched());

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
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  ClipPath(
                    clipper: HeaderCurvedClipper(),
                    child: Container(
                      width: double.infinity,
                      height: 230,
                      decoration: const BoxDecoration(color: pink),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 30,
                          left: 24,
                          right: 24,
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'WELCOME BACK',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.profile.username,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned(bottom: 0, child: _buildAvatar()),
                ],
              ),

              const SizedBox(height: 18),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Username
                        Text(
                          widget.profile.username,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: darkText,
                          ),
                        ),

                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: pink.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                size: 16,
                                color: pink,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Role: ${widget.profile.role}',
                                style: const TextStyle(
                                  color: pink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (widget.profile.role == Roles.admin) ...[
                          const SizedBox(height: 30),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'MY POSTS',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: darkText,
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
                                      color: pink.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$count Posts',
                                      style: const TextStyle(
                                        color: pink,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          MyPostList(userId: widget.profile.id),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    const double avatarSize = 115;

    return Container(
      width: avatarSize,
      height: avatarSize,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child:
            widget.profile.avatarUrl == null ||
                widget.profile.avatarUrl!.isEmpty
            ? Container(
                color: background,
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: Color(0xFF999999),
                ),
              )
            : CachedNetworkImage(
                imageUrl: widget.profile.avatarUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: pink,
                    ),
                  );
                },
                errorWidget: (context, url, error) {
                  return const Icon(
                    Icons.error_outline,
                    color: Color(0xFF999999),
                    size: 35,
                  );
                },
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
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
