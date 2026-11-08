import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/my_post_list/my_post_list_bloc.dart';
import 'post_card.dart';

class MyPostList extends StatelessWidget {
  const MyPostList({super.key, required this.userId});

  final String userId;

  static const Color _primaryYellow = Color(0xFFFFB800);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyPostListBloc, MyPostListState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: switch (state.status) {
            MyPostListStatus.initial ||
            MyPostListStatus.loading => const Center(
              key: ValueKey('loading'),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: _PostLoadingIndicator(),
              ),
            ),

            MyPostListStatus.failure => Center(
              key: const ValueKey('failure'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 36,
                ),
                child: _PostErrorView(
                  message: state.failure?.message ?? 'Unknown error',
                ),
              ),
            ),

            _ => _buildList(context, state),
          },
        );
      },
    );
  }

  Widget _buildList(BuildContext context, MyPostListState state) {
    if (state.posts.isEmpty) {
      return const Center(key: ValueKey('empty'), child: _EmptyPostsView());
    }

    return ListView.builder(
      key: const ValueKey('posts'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: state.hasReachedMax
          ? state.posts.length
          : state.posts.length + 1,
      itemBuilder: (context, index) {
        if (index >= state.posts.length) {
          return state.status == MyPostListStatus.fetchingNextPage
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: _primaryYellow,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink();
        }

        final post = state.posts[index];

        return _AnimatedPostItem(
          key: ValueKey(post.postId),
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PostCard(
              post: post,
              onToggleLike: () {
                context.read<MyPostListBloc>().add(
                  MyPostLikeToggled(post: post),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _PostLoadingIndicator extends StatelessWidget {
  const _PostLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 30,
      height: 30,
      child: CircularProgressIndicator(
        color: Color(0xFFFFB800),
        strokeWidth: 2.8,
      ),
    );
  }
}

class _EmptyPostsView extends StatelessWidget {
  const _EmptyPostsView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB800).withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.post_add_rounded,
              size: 38,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Your posts will appear here once you share something.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF8C8C8C),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostErrorView extends StatelessWidget {
  const _PostErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            size: 34,
            color: Color(0xFFE53935),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Unable to load posts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E1E1E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Color(0xFF8C8C8C),
          ),
        ),
      ],
    );
  }
}

class _AnimatedPostItem extends StatefulWidget {
  const _AnimatedPostItem({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<_AnimatedPostItem> createState() => _AnimatedPostItemState();
}

class _AnimatedPostItemState extends State<_AnimatedPostItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(
      Duration(milliseconds: widget.index < 5 ? widget.index * 65 : 0),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
