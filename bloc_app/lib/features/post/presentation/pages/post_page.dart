import 'package:core/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/route_constants.dart';
import '../blocs/post_list/post_list_bloc.dart';
import '../widgets/post_card.dart';

class PostPage extends StatelessWidget {
  const PostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PostView();
  }
}

class PostView extends StatefulWidget {
  const PostView({super.key});

  @override
  State<PostView> createState() => _PostViewState();
}

class _PostViewState extends State<PostView>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  static const Color _pinkPrimary = Color(0xFFE91E63);
  static const Color _dark = Color(0xFF263238);
  static const Color _bgColor = Color(0xFFF3F3F3);
  static const Color _textMuted = Color(0xFF7B8794);
  static const Color _red = Color(0xFFE53935);

  static const LinearGradient _headerGradient = LinearGradient(
    colors: [Color(0xFFE91E63), Color(0xFFD81B60), Color(0xFFC2185B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient _fabGradient = LinearGradient(
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

    _scrollController.addListener(_onScroll);

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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PostListBloc>().add(PostListNextPageFetched());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: Container(
          height: 130,
          decoration: const BoxDecoration(gradient: _headerGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 5),
              child: Align(
                alignment: Alignment.topLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.article_outlined,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Posts',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: _fabGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _pinkPrimary.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            context.pushNamed(RouteNames.postCreate);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'New Post',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      body: BlocConsumer<PostListBloc, PostListState>(
        listenWhen: (previous, current) {
          final isTransientFailure =
              previous.transientFailure == null &&
              current.transientFailure != null;

          final prevScrollEventId = previous.scrollToTopEventId;
          final currentScrollEventId = current.scrollToTopEventId;

          final isScrollToTopEvent =
              prevScrollEventId != currentScrollEventId &&
              currentScrollEventId != null;

          return isTransientFailure || isScrollToTopEvent;
        },
        listener: (context, state) {
          if (state.scrollToTopEventId != null) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
              );
            }

            context.read<PostListBloc>().add(PostListScrollEventConsumed());
          } else if (state.transientFailure != null) {
            showErrorSnackbar(
              context,
              message: state.transientFailure!.message,
            );

            context.read<PostListBloc>().add(
              PostListTransientFailureConsumed(),
            );
          }
        },
        builder: (context, state) {
          switch (state.status) {
            case PostListStatus.initial:
            case PostListStatus.loading:
              return const Center(
                child: CircularProgressIndicator(
                  color: _pinkPrimary,
                  strokeWidth: 3,
                ),
              );

            case PostListStatus.failure:
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: _red.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: _red,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Something went wrong',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: _dark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.failure?.message ?? 'Unknown error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _textMuted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        decoration: BoxDecoration(
                          gradient: _fabGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _pinkPrimary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            context.read<PostListBloc>().add(PostListFetched());
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text(
                            'Retry',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );

            case _:
              if (state.posts.isEmpty) {
                return RefreshIndicator(
                  color: _pinkPrimary,
                  backgroundColor: Colors.white,
                  onRefresh: () async {
                    context.read<PostListBloc>().add(PostListRefreshed());
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(26),
                                  decoration: BoxDecoration(
                                    color: _pinkPrimary.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.article_outlined,
                                    size: 55,
                                    color: _pinkPrimary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'No Posts Yet',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _dark,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'There are no posts available right now.\n'
                                  'Log in with an admin account to create your first post!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _textMuted,
                                    height: 1.6,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }

              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: RefreshIndicator(
                    color: _pinkPrimary,
                    backgroundColor: Colors.white,
                    onRefresh: () async {
                      context.read<PostListBloc>().add(PostListRefreshed());
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      itemCount: state.hasReachedMax
                          ? state.posts.length + 1
                          : state.posts.length + 2,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 12, top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 14,
                                  color: _textMuted,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Pull down to refresh',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textMuted,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final postIndex = index - 1;

                        if (postIndex >= state.posts.length) {
                          return state.status == PostListStatus.fetchingNextPage
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: _pinkPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'Loading more posts...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink();
                        }

                        final post = state.posts[postIndex];

                        return PostCard(
                          key: ValueKey(post.postId),
                          post: post,
                          animationIndex: postIndex,
                          onToggleLike: () {
                            context.read<PostListBloc>().add(
                              PostLikeToggled(post: post),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}
