import 'package:cached_network_image/cached_network_image.dart';
import 'package:domain/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/router/route_constants.dart';
import '../../../auth/presentation/bloc/authentication/authentication_bloc.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onToggleLike,
    this.animationIndex = 0,
  });

  final PostDisplay post;
  final VoidCallback? onToggleLike;
  final int animationIndex;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  static const Color _cardBgColor = Colors.white;
  static const Color _pink = Color(0xFFE91E63);
  static const Color _dark = Color(0xFF263238);
  static const Color _subtleText = Color(0xFF7B8794);
  static const Color _likeColor = Color(0xFFE91E63);
  static const Color _avatarBg = Color(0xFF537380);
  static const Color _background = Color(0xFFF3F3F3);

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _isPressed = false;
  bool _showLikeAnimation = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    Future.delayed(
      Duration(milliseconds: (widget.animationIndex * 65).clamp(0, 450)),
      () {
        if (mounted) {
          _animationController.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleLike() {
    widget.onToggleLike?.call();

    setState(() {
      _showLikeAnimation = true;
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _showLikeAnimation = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    final currentUserId = context.select(
      (AuthenticationBloc bloc) => bloc.state.user?.id,
    );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: AnimatedScale(
          scale: _isPressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _cardBgColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withValues(alpha: 0.035)),
              boxShadow: [
                BoxShadow(
                  color: _dark.withValues(alpha: 0.055),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  context.pushNamed(
                    RouteNames.postDetail,
                    pathParameters: {'postId': post.postId},
                  );
                },
                onHighlightChanged: (value) {
                  setState(() {
                    _isPressed = value;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          if (currentUserId != post.authorId) {
                            context.pushNamed(
                              RouteNames.userDetail,
                              pathParameters: {'userId': post.authorId},
                            );
                          }
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _pink.withValues(alpha: 0.65),
                                  width: 1.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 19,
                                backgroundColor: _avatarBg,
                                child:
                                    post.authorAvatarUrl == null ||
                                        post.authorAvatarUrl!.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 22,
                                        color: Colors.white,
                                      )
                                    : ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: post.authorAvatarUrl!,
                                          placeholder: (context, url) =>
                                              const Center(
                                                child: SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: _pink,
                                                      ),
                                                ),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(
                                                Icons.person,
                                                size: 22,
                                                color: Colors.white,
                                              ),
                                          fit: BoxFit.cover,
                                          width: 38,
                                          height: 38,
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
                                      fontSize: 15,
                                      color: _dark,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 12,
                                        color: _subtleText,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat(
                                          'yyyy-MM-dd HH:mm',
                                        ).format(post.postCreatedAt),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: _subtleText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.more_horiz_rounded,
                              color: _subtleText,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 17),
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _dark,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 9),
                      if (post.imageUrl != null &&
                          post.imageUrl!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: CachedNetworkImage(
                            imageUrl: post.imageUrl!,
                            placeholder: (context, url) => Container(
                              height: 180,
                              color: _background,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: _pink,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 180,
                              color: _background,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  size: 35,
                                  color: _subtleText,
                                ),
                              ),
                            ),
                            width: double.infinity,
                            height: 190,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        post.content,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF59636B),
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Divider(
                        height: 1,
                        thickness: 1,
                        color: _dark.withValues(alpha: 0.07),
                      ),

                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: _handleLike,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 5,
                              ),
                              child: Row(
                                children: [
                                  AnimatedScale(
                                    scale: _showLikeAnimation ? 1.35 : 1,
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOutBack,
                                    child: Icon(
                                      post.currentUserLiked
                                          ? Icons.thumb_up_rounded
                                          : Icons.thumb_up_alt_outlined,
                                      size: 20,
                                      color: post.currentUserLiked
                                          ? _likeColor
                                          : _subtleText,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    post.likesCount.toString(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: post.currentUserLiked
                                          ? _likeColor
                                          : _subtleText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 18),

                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 19,
                            color: _pink,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            post.commentsCount.toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _subtleText,
                            ),
                          ),

                          const SizedBox(width: 5),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
