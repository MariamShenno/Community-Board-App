import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/constants.dart';
import 'package:domain/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/router/route_constants.dart';
import '../../../auth/presentation/bloc/authentication/authentication_bloc.dart';
import '../blocs/comment_list/comment_list_bloc.dart';

class CommentCard extends StatelessWidget {
  const CommentCard({super.key, required this.comment});

  final CommentDisplay comment;

  static const Color _pinkPrimary = Color(0xFFE91E63);
  static const Color _pinkLight = Color(0xFFFCE4EC);
  static const Color _textDark = Color(0xFF263238);
  static const Color _textMuted = Color(0xFF89939D);
  static const Color _bgColor = Color(0xFFF5F5F7);
  static const Color _red = Color(0xFFE53935);

  void _showEditCommentDialog(BuildContext context) {
    final commentListBloc = context.read<CommentListBloc>();

    showDialog(
      context: context,
      builder: (_) {
        return BlocProvider.value(
          value: commentListBloc,
          child: _EditCommentDialog(comment: comment),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthenticationBloc>().state.user;
    final currentUserRole = currentUser?.role;

    final bool canEdit = currentUser?.id == comment.authorId;
    final bool canDelete = canEdit || (currentUserRole == Roles.admin);

    return BlocSelector<CommentListBloc, CommentListState, bool>(
      selector: (state) {
        return state.submittingCommentId == comment.id;
      },
      builder: (context, isSubmitting) {
        if (isSubmitting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 25),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: _pinkPrimary,
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
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
                InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    if (currentUser?.id != comment.authorId) {
                      context.pushNamed(
                        RouteNames.userDetail,
                        pathParameters: {'userId': comment.authorId},
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
                      radius: 18,
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
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _pinkPrimary,
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                      Icons.person,
                                      size: 19,
                                      color: _textMuted,
                                    ),
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
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('MM-dd HH:mm').format(comment.createdAt),
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
                if (canEdit || canDelete) ...[
                  const SizedBox(width: 5),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canEdit)
                        _CommentActionButton(
                          icon: Icons.edit_outlined,
                          color: _pinkPrimary,
                          tooltip: 'Edit Comment',
                          onTap: () => _showEditCommentDialog(context),
                        ),

                      if (canDelete)
                        _CommentActionButton(
                          icon: Icons.delete_outline_rounded,
                          color: _red,
                          tooltip: 'Delete Comment',
                          onTap: () async {
                            final commentListBloc = context
                                .read<CommentListBloc>();

                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) {
                                return AlertDialog(
                                  backgroundColor: Colors.white,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: const Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline_rounded,
                                        color: _red,
                                        size: 23,
                                      ),
                                      SizedBox(width: 9),
                                      Expanded(
                                        child: Text(
                                          'Confirm Deletion',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: _textDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: const Text(
                                    'Are you sure you want to delete this comment?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.6,
                                      color: _textMuted,
                                    ),
                                  ),
                                  actionsPadding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    18,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop(false);
                                      },
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: _textMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop(true);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _red,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmed == true) {
                              commentListBloc.add(
                                CommentDeleted(
                                  postId: comment.postId,
                                  commentId: comment.id,
                                ),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CommentActionButton extends StatelessWidget {
  const _CommentActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _EditCommentDialog extends StatefulWidget {
  const _EditCommentDialog({required this.comment});

  final CommentDisplay comment;

  @override
  State<_EditCommentDialog> createState() => __EditCommentDialogState();
}

class __EditCommentDialogState extends State<_EditCommentDialog> {
  late final TextEditingController _textController;

  bool _isSaveEnabled = false;

  static const Color _pinkPrimary = Color(0xFFE91E63);
  static const Color _pinkLight = Color(0xFFFCE4EC);
  static const Color _textDark = Color(0xFF263238);
  static const Color _textMuted = Color(0xFF89939D);
  static const Color _bgColor = Color(0xFFF5F5F7);

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController(text: widget.comment.content);

    _textController.addListener(_updateSaveButtonState);
    _updateSaveButtonState();
  }

  void _updateSaveButtonState() {
    final isNotEmpty = _textController.text.trim().isNotEmpty;
    final isChanged = _textController.text != widget.comment.content;

    if (mounted) {
      setState(() {
        _isSaveEnabled = isNotEmpty && isChanged;
      });
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_updateSaveButtonState);
    _textController.dispose();
    super.dispose();
  }

  void _submit(bool isSubmitting) {
    if (!_isSaveEnabled || isSubmitting) return;

    final newContent = _textController.text.trim();

    context.read<CommentListBloc>().add(
      CommentEdited(commentId: widget.comment.id, newContent: newContent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CommentListBloc, CommentListState>(
      listener: (context, state) {
        final isSubmitting = state.submittingCommentId == widget.comment.id;

        if (!isSubmitting && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: BlocSelector<CommentListBloc, CommentListState, bool>(
        selector: (state) {
          return state.submittingCommentId == widget.comment.id;
        },
        builder: (context, isSubmitting) {
          return AlertDialog(
            backgroundColor: Colors.white,
            elevation: 6,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
            contentPadding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
            actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _pinkLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: _pinkPrimary,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Comment',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Update your comment',
                        style: TextStyle(
                          fontSize: 11,
                          color: _textMuted,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _pinkPrimary.withValues(alpha: 0.15)),
              ),
              child: TextField(
                controller: _textController,
                autofocus: true,
                maxLines: 5,
                minLines: 3,
                enabled: !isSubmitting,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Write your comment...',
                  hintStyle: TextStyle(color: _textMuted, fontSize: 13),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: _textDark,
                  height: 1.6,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: _textMuted,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(width: 5),

              ElevatedButton(
                onPressed: _isSaveEnabled && !isSubmitting
                    ? () => _submit(isSubmitting)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pinkPrimary,
                  disabledBackgroundColor: _pinkPrimary.withValues(alpha: 0.35),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
