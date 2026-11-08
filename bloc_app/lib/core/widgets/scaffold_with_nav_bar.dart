import 'package:core/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/authentication/authentication_bloc.dart';
import '../../features/post/presentation/blocs/post_list/post_list_bloc.dart';
import '../blocs/realtime/realtime_bloc.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const Color _bgColor = Color(0xFFF3F3F3);
  static const Color _activePink = Color(0xFFE91E63);

  static const Color _inactiveGrey = Color(0xFF8A94A6);
  static const Color _primaryDark = Color(0xFF263238);

  @override
  Widget build(BuildContext context) {
    return BlocListener<RealtimeBloc, RealtimeState>(
      listener: (context, state) {
        if (state is RealtimeNewPostArrived) {
          final currentUserId = context
              .read<AuthenticationBloc>()
              .state
              .user
              ?.id;

          final newPost = state.post;

          if (newPost.authorId != currentUserId) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  backgroundColor: _primaryDark,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  content: const Text(
                    'New post has arrived',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  action: SnackBarAction(
                    label: 'View',
                    textColor: _activePink,
                    onPressed: () {
                      context.read<PostListBloc>().add(
                        PostListNewPostPrepended(post: newPost),
                      );

                      context.read<PostListBloc>().add(
                        PostListScrollToTopRequested(),
                      );
                    },
                  ),
                ),
              );
          }

          context.read<RealtimeBloc>().add(const RealtimeStateResetRequested());
        }

        if (state is RealtimeConnectionFailure) {
          showErrorSnackbar(
            context,
            message: 'Realtime Error: ${state.message}',
          );

          context.read<RealtimeBloc>().add(const RealtimeStateResetRequested());
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,

        // Keep StatefulNavigationShell directly in Scaffold.
        // This prevents Duplicate GlobalKey errors.
        body: navigationShell,

        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,

            selectedItemColor: _activePink,
            unselectedItemColor: _inactiveGrey,

            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),

            selectedIconTheme: const IconThemeData(size: 25),
            unselectedIconTheme: const IconThemeData(size: 23),

            showSelectedLabels: true,
            showUnselectedLabels: true,

            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: _AnimatedNavIcon(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                ),
                activeIcon: _AnimatedNavIcon(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  isActive: true,
                ),
                label: 'Post',
              ),
              BottomNavigationBarItem(
                icon: _AnimatedNavIcon(
                  icon: Icons.search_outlined,
                  activeIcon: Icons.search_rounded,
                ),
                activeIcon: _AnimatedNavIcon(
                  icon: Icons.search_outlined,
                  activeIcon: Icons.search_rounded,
                  isActive: true,
                ),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: _AnimatedNavIcon(
                  icon: Icons.person_outlined,
                  activeIcon: Icons.person_rounded,
                ),
                activeIcon: _AnimatedNavIcon(
                  icon: Icons.person_outlined,
                  activeIcon: Icons.person_rounded,
                  isActive: true,
                ),
                label: 'Profile',
              ),
            ],

            currentIndex: navigationShell.currentIndex,

            onTap: (int index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AnimatedNavIcon extends StatelessWidget {
  const _AnimatedNavIcon({
    required this.icon,
    required this.activeIcon,
    this.isActive = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isActive ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Icon(isActive ? activeIcon : icon, key: ValueKey(isActive)),
      ),
    );
  }
}
