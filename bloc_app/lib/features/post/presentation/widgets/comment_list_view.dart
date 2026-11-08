import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/comment_list/comment_list_bloc.dart';
import 'comment_card.dart';

class CommentListView extends StatelessWidget {
  const CommentListView({super.key});

  static const Color _primaryColor = Color(0xFFE91E63);


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentListBloc, CommentListState>(
      builder: (context, state) {
        switch (state.status) {
          case CommentListStatus.initial || CommentListStatus.loading:
            return const SliverFillRemaining(
              child: Center(
                child: _CommentLoadingIndicator(),
              ),
            );

          case CommentListStatus.failure:
            return SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _CommentErrorView(
                    message:
                        state.failure?.message ?? 'Unknown error',
                  ),
                ),
              ),
            );

          case _:
            if (state.comments.isEmpty) {
              return const SliverToBoxAdapter(
                child: _EmptyCommentsView(),
              );
            }

            return SliverList.builder(
              itemCount: state.hasReachedMax
                  ? state.comments.length
                  : state.comments.length + 1,
              itemBuilder: (context, index) {
                if (index >= state.comments.length) {
                  return state.status ==
                          CommentListStatus.fetchingNextPage
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink();
                }

                return _AnimatedCommentItem(
                  key: ValueKey(state.comments[index].id),
                  index: index,
                  child: CommentCard(
                    comment: state.comments[index],
                  ),
                );
              },
            );
        }
      },
    );
  }
}

class _CommentLoadingIndicator extends StatelessWidget {
  const _CommentLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 30,
      height: 30,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: Color(0xFFE91E63),
      ),
    );
  }
}

class _EmptyCommentsView extends StatelessWidget {
  const _EmptyCommentsView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 48,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color:  Color(0xFFFCE4EC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mode_comment_outlined,
              color: Color(0xFFE91E63),
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No comments yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Be the first to share your thoughts!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF89939D),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentErrorView extends StatelessWidget {
  const _CommentErrorView({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFE53935),
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Something went wrong',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF263238),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF89939D),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _AnimatedCommentItem extends StatefulWidget {
  const _AnimatedCommentItem({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<_AnimatedCommentItem> createState() =>
      _AnimatedCommentItemState();
}

class _AnimatedCommentItemState extends State<_AnimatedCommentItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
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
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}