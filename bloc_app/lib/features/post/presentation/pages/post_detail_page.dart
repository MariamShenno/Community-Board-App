import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/constants.dart';
import 'package:core/utils.dart';
import 'package:domain/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../../core/di/di.dart';

import '../../../auth/presentation/bloc/authentication/authentication_bloc.dart';
import '../blocs/comment_list/comment_list_bloc.dart';
import '../blocs/post_detail/post_detail_bloc.dart';

class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              getIt<PostDetailBloc>()..add(PostDetailFetched(postId: postId)),
        ),
        BlocProvider(
          create: (context) =>
              getIt<CommentListBloc>()..add(CommentListFetched(postId: postId)),
        ),
      ],
      child: BlocListener<PostDetailBloc, PostDetailState>(
        listenWhen: (previous, current) {
          final didDelete =
              !previous.deletionSuccess && current.deletionSuccess;

          final didFail =
              previous.transientFailure == null &&
              current.transientFailure != null;

          return didDelete || didFail;
        },
        listener: (context, state) {
          if (state.deletionSuccess) {
            final navigator = Navigator.of(context);

            if (navigator.canPop()) navigator.pop();
            if (navigator.canPop()) navigator.pop();

            return;
          }

          if (state.transientFailure != null) {
            showErrorSnackbar(
              context,
              message: state.transientFailure!.message,
            );

            context.read<PostDetailBloc>().add(
              PostDetailTransientFailureConsumed(),
            );
          }
        },
        child: PostDetailView(postId: postId),
      ),
    );
  }
}

class PostDetailView extends StatefulWidget {
  const PostDetailView({super.key, required this.postId});

  final String postId;

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  static const Color _pinkPrimary = Color(0xFFE91E63);
  static const Color _pinkDark = Color(0xFFC2185B);
  static const Color _pinkLight = Color(0xFFFCE4EC);
  static const Color _bgColor = Color(0xFFF5F5F7);
  static const Color _textDark = Color(0xFF263238);
  static const Color _textMuted = Color(0xFF89939D);
  static const Color _red = Color(0xFFE53935);

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
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
      context.read<CommentListBloc>().add(
        CommentListNextPageFetched(postId: widget.postId),
      );
    }
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    final postDetailBloc = context.read<PostDetailBloc>();

    showDialog(
      context: context,
      barrierDismissible:
          postDetailBloc.state.status != PostDetailStatus.submitting,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: postDetailBloc,
          child: BlocBuilder<PostDetailBloc, PostDetailState>(
            builder: (context, state) {
              final isSubmitting = state.status == PostDetailStatus.submitting;

              return PopScope(
                canPop: !isSubmitting,
                child: AlertDialog(
                  backgroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: _red, size: 24),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Confirm Deletion',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: _textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    'Are you sure you want to delete this post?',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  actions: [
                    TextButton(
                      onPressed: isSubmitting
                          ? null
                          : () => Navigator.of(dialogContext).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: _textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () {
                              postDetailBloc.add(const PostDeleted());
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Delete',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.select(
      (AuthenticationBloc bloc) => bloc.state.user,
    );

    final currentUserRole = currentUser?.role;

    return BlocBuilder<PostDetailBloc, PostDetailState>(
      builder: (context, state) {
        switch (state.status) {
          case PostDetailStatus.initial:
          case PostDetailStatus.loading:
            return const Scaffold(
              backgroundColor: _bgColor,
              appBar: _CustomAppBar(title: 'Post Details'),
              body: Center(
                child: CircularProgressIndicator(color: _pinkPrimary),
              ),
            );

          case PostDetailStatus.failure:
            return Scaffold(
              backgroundColor: _bgColor,
              appBar: const _CustomAppBar(title: 'Post Details'),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          color: _pinkLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          size: 38,
                          color: _pinkPrimary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Unable to load post',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.failure?.message ?? 'Unknown error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<PostDetailBloc>().add(
                            PostDetailFetched(postId: widget.postId),
                          );
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pinkPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

          case _:
            final post = state.post!;

            final canModify =
                (currentUser?.id == post.authorId) ||
                (currentUserRole == Roles.admin);

            return Scaffold(
              backgroundColor: _bgColor,
              appBar: _CustomAppBar(
                title: 'Post Details',
                actions: [
                  if (canModify)
                    IconButton(
                      onPressed: () {
                        context.pushNamed(
                          RouteNames.postEdit,
                          pathParameters: {'postId': post.postId},
                        );
                      },
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 21,
                      ),
                      tooltip: 'Edit Post',
                    ),
                  if (canModify)
                    IconButton(
                      onPressed: () {
                        _showDeleteConfirmDialog(context);
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                      tooltip: 'Delete Post',
                    ),
                  const SizedBox(width: 5),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildContent(context, post),
                      ),
                    ),
                  ),
                  _StyledCommentInputField(
                    postId: widget.postId,
                    scrollController: _scrollController,
                  ),
                ],
              ),
            );
        }
      },
    );
  }

  Widget _buildContent(BuildContext context, PostDisplay post) {
    return BlocListener<CommentListBloc, CommentListState>(
      listenWhen: (previous, current) {
        return previous.transientFailure == null &&
            current.transientFailure != null;
      },
      listener: (context, state) {
        showErrorSnackbar(context, message: state.transientFailure!.message);

        context.read<CommentListBloc>().add(
          CommentListTransientFailureConsumed(),
        );
      },
      child: RefreshIndicator(
        color: _pinkPrimary,
        onRefresh: () async {
          context.read<PostDetailBloc>().add(
            PostDetailFetched(postId: widget.postId),
          );

          context.read<CommentListBloc>().add(
            CommentListRefreshed(postId: widget.postId),
          );
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                child: _buildPostDetail(context, post),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _pinkLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 19,
                        color: _pinkPrimary,
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    const Spacer(),
                    BlocBuilder<CommentListBloc, CommentListState>(
                      builder: (context, state) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: Text(
                            '${state.comments.length}',
                            style: const TextStyle(
                              color: _pinkDark,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const _StyledCommentListView(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostDetail(BuildContext context, PostDisplay post) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEEEF1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    final currentUserId = context
                        .read<AuthenticationBloc>()
                        .state
                        .user
                        ?.id;

                    if (currentUserId != post.authorId) {
                      context.pushNamed(
                        RouteNames.userDetail,
                        pathParameters: {'userId': post.authorId},
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _pinkLight,
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFF1F2F4),
                      child: post.authorAvatarUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 24,
                              color: _textMuted,
                            )
                          : ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: post.authorAvatarUrl!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _pinkPrimary,
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.person, color: _textMuted),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorUsername,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: _textMuted,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              DateFormat(
                                'yyyy-MM-dd • HH:mm',
                              ).format(post.postCreatedAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: _textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _textDark,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 10),

            // Post Content
            Text(
              post.content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF58636D),
                height: 1.8,
              ),
            ),
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: _bgColor,
                      child: const Center(
                        child: CircularProgressIndicator(color: _pinkPrimary),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 160,
                    color: _bgColor,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 35,
                        color: _textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 19),

            Divider(height: 1, color: Colors.grey.withValues(alpha: 0.16)),

            const SizedBox(height: 15),

            Row(
              children: [
                _buildPostAction(
                  icon: post.currentUserLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: post.likesCount.toString(),
                  isActive: post.currentUserLiked,
                  activeColor: _pinkPrimary,
                  onTap: () {
                    context.read<PostDetailBloc>().add(
                      const PostDetailLikeToggled(),
                    );
                  },
                ),
                const SizedBox(width: 10),
                _buildPostAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: post.commentsCount.toString(),
                  isActive: false,
                  activeColor: const Color(0xFF65717B),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostAction({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? _pinkLight : const Color(0xFFF7F7F8),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isActive
                ? _pinkPrimary.withValues(alpha: 0.22)
                : const Color(0xFFEEEEF0),
          ),
        ),
        child: Row(
          children: [
            AnimatedScale(
              scale: isActive ? 1.12 : 1,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 18,
                color: isActive ? _pinkPrimary : activeColor,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? _pinkDark : _textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyledCommentListView extends StatelessWidget {
  const _StyledCommentListView();

  static const Color _pinkPrimary = Color(0xFFE91E63);
  static const Color _textDark = Color(0xFF263238);
  static const Color _textMuted = Color(0xFF89939D);
  static const Color _bgColor = Color(0xFFF5F5F7);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentListBloc, CommentListState>(
      builder: (context, state) {
        if (state.status == CommentListStatus.loading &&
            state.comments.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(25),
              child: Center(
                child: CircularProgressIndicator(color: _pinkPrimary),
              ),
            ),
          );
        }

        if (state.comments.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 35),
              child: Column(
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 42,
                    color: Color(0xFFB0BEC5),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No comments yet',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Be the first to share your thoughts!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: _textMuted),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= state.comments.length) {
                  return const Padding(
                    padding: EdgeInsets.all(18),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _pinkPrimary,
                      ),
                    ),
                  );
                }

                final comment = state.comments[index];

                return TweenAnimationBuilder<double>(
                  key: ValueKey(comment),
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 300 + (index % 5) * 70),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEEEEF0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.025),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFCE4EC),
                            ),
                            child: CircleAvatar(
                              radius: 17,
                              backgroundColor: _bgColor,
                              child: comment.authorAvatarUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 19,
                                      color: _textMuted,
                                    )
                                  : ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: comment.authorAvatarUrl!,
                                        width: 34,
                                        height: 34,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                              Icons.person,
                                              color: _textMuted,
                                            ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        comment.authorUsername,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: _textDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateFormat(
                                        'MM-dd HH:mm',
                                      ).format(comment.createdAt),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: _textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  comment.content,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF58636D),
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: state.hasReachedMax
                  ? state.comments.length
                  : state.comments.length + 1,
            ),
          ),
        );
      },
    );
  }
}

class _StyledCommentInputField extends StatefulWidget {
  const _StyledCommentInputField({
    required this.postId,
    required this.scrollController,
  });

  final String postId;
  final ScrollController scrollController;

  @override
  State<_StyledCommentInputField> createState() =>
      _StyledCommentInputFieldState();
}

class _StyledCommentInputFieldState extends State<_StyledCommentInputField> {
  final TextEditingController _controller = TextEditingController();

  static const Color _pinkPrimary = Color(0xFFE91E63);
  static const Color _pinkDark = Color(0xFFC2185B);
  static const Color _bgColor = Color(0xFFF5F5F7);

  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;

    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _controller.text.trim();

    if (text.isEmpty) return;

    context.read<CommentListBloc>().add(
      CommentAdded(postId: widget.postId, content: text),
    );

    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFEEEEF0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _hasText
                      ? _pinkPrimary.withValues(alpha: 0.4)
                      : const Color(0xFFE9E9EC),
                ),
              ),
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Write a comment...',
                  hintStyle: TextStyle(color: Color(0xFF9AA4AE), fontSize: 13),
                  border: InputBorder.none,
                  icon: Icon(
                    Icons.edit_outlined,
                    color: _pinkPrimary,
                    size: 19,
                  ),
                ),
                style: const TextStyle(fontSize: 14, color: Color(0xFF263238)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedScale(
            scale: _hasText ? 1 : 0.92,
            duration: const Duration(milliseconds: 200),
            child: InkWell(
              onTap: _hasText ? _submitComment : null,
              borderRadius: BorderRadius.circular(25),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _hasText ? _pinkPrimary : const Color(0xFFE6E7E9),
                  shape: BoxShape.circle,
                  boxShadow: _hasText
                      ? [
                          BoxShadow(
                            color: _pinkDark.withValues(alpha: 0.20),
                            blurRadius: 9,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: _hasText ? Colors.white : Colors.grey,
                  size: 19,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CustomAppBar({required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  static const Color _pinkDark = Color(0xFFC2185B);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _pinkDark,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: kToolbarHeight,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 19,
        ),
        onPressed: () => context.pop(),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
