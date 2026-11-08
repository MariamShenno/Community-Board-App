import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/comment_list/comment_list_bloc.dart';

class CommentInputField extends StatefulWidget {
  const CommentInputField({
    super.key,
    required this.postId,
    required this.scrollController,
  });

  final String postId;
  final ScrollController scrollController;

  @override
  State<CommentInputField> createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<CommentInputField> {
  final _commentController = TextEditingController();

  static const Color _primaryColor = Color(0xFFE91E63);
  static const Color _darkTextColor = Color(0xFF263238);
  static const Color _secondaryTextColor = Color(0xFF89939D);
  static const Color _backgroundColor = Color(0xFFF5F5F7);

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    context.read<CommentListBloc>().add(
      CommentAdded(postId: widget.postId, content: content),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) widget.scrollController.jumpTo(0);
    });

    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CommentListBloc, CommentListState, bool>(
      selector: (state) {
        return state.status == CommentListStatus.submitting;
      },
      builder: (context, isSubmitting) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      maxHeight: 120,
                    ),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 0.8,
                      ),
                    ),
                    child: TextField(
                      controller: _commentController,
                      enabled: !isSubmitting,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: isSubmitting
                          ? null
                          : (_) => _submitComment(),
                      style: const TextStyle(
                        color: _darkTextColor,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        hintStyle: TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 13,
                        ),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 15, right: 8),
                          child: Icon(
                            Icons.mode_comment_outlined,
                            color: _secondaryTextColor,
                            size: 19,
                          ),
                        ),
                        prefixIconConstraints: BoxConstraints(
                          minWidth: 42,
                          minHeight: 48,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 13,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isSubmitting
                        ? _primaryColor.withValues(alpha: 0.12)
                        : _primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: isSubmitting
                        ? []
                        : [
                            BoxShadow(
                              color: _primaryColor.withValues(alpha: 0.22),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: isSubmitting
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _primaryColor,
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: _submitComment,
                          splashRadius: 22,
                          icon: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
