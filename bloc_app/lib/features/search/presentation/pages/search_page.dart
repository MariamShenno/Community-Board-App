import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router/route_constants.dart';
import '../../../../core/di/di.dart';
import '../../../auth/presentation/bloc/authentication/authentication_bloc.dart';
import '../../../post/presentation/widgets/post_card.dart';
import '../blocs/search/search_bloc.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SearchBloc>(),
      child: const SearchView(),
    );
  }
}

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;

  static const LinearGradient _primaryGradient = LinearGradient(
    colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color _pinkPrimary = Color(0xFFE91E63);
  static const Color _pinkDark = Color(0xFFC2185B);
  static const Color _pinkLight = Color(0xFFFCE4EC);
  static const Color _bgColor = Color(0xFFF3F3F3);
  static const Color _primaryDark = Color(0xFF263238);
  static const Color _subtleText = Color(0xFF7B8794);

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_tabListener);

    _searchController.addListener(_searchListener);
  }

  void _tabListener() {
    if (_tabController.indexIsChanging) {
      setState(() {});

      context.read<SearchBloc>().add(
        SearchTabChanged(tabIndex: _tabController.index),
      );
    }
  }

  void _searchListener() {
    setState(() {});

    context.read<SearchBloc>().add(
      SearchQueryChanged(query: _searchController.text),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_searchListener);
    _tabController.removeListener(_tabListener);

    _searchController.dispose();
    _tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SearchBloc, SearchState>(
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

        context.read<SearchBloc>().add(SearchTransientFailureConsumed());
      },
      builder: (context, state) {
        final isLoading =
            state.status == SearchStatus.loadingUsers ||
            state.status == SearchStatus.loadingPosts;

        return Scaffold(
          backgroundColor: _bgColor,
          extendBodyBehindAppBar: false,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(180),
            child: Container(
              decoration: const BoxDecoration(
                gradient: _primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Title
                    const Padding(
                      padding: EdgeInsets.fromLTRB(18, 8, 18, 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Search',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 46,
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: const TextStyle(
                            fontSize: 14,
                            color: _primaryDark,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search users or posts...',
                            hintStyle: const TextStyle(
                              color: _subtleText,
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: _pinkPrimary,
                              size: 22,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    onPressed: _searchController.clear,
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: _subtleText,
                                      size: 19,
                                    ),
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: _pinkLight,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(
                          text: 'Users',
                          icon: Icon(Icons.people_alt_outlined, size: 18),
                          height: 48,
                        ),
                        Tab(
                          text: 'Posts',
                          icon: Icon(Icons.article_outlined, size: 18),
                          height: 48,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          body: Column(
            children: [
              // Loading Indicator
              SizedBox(
                height: 3,
                child: isLoading
                    ? const LinearProgressIndicator(
                        color: _pinkPrimary,
                        backgroundColor: _pinkLight,
                      )
                    : null,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final isUsersTab = child.key == const ValueKey('UsersTab');

                    final offset = isUsersTab
                        ? const Offset(-0.08, 0)
                        : const Offset(0.08, 0);

                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: offset,
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _tabController.index == 0
                      ? KeyedSubtree(
                          key: const ValueKey('UsersTab'),
                          child: _buildUserResultsTab(context, state),
                        )
                      : KeyedSubtree(
                          key: const ValueKey('PostsTab'),
                          child: _buildPostResultsTab(context, state),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserResultsTab(BuildContext context, SearchState state) {
    if (state.status == SearchStatus.loadingUsers) {
      return const Center(
        child: CircularProgressIndicator(color: _pinkPrimary, strokeWidth: 2.5),
      );
    }

    if (state.status == SearchStatus.failure) {
      return _buildMessageState(
        icon: Icons.error_outline_rounded,
        title: 'Something went wrong',
        subtitle: 'Failed to search: ${state.failure?.message}',
      );
    }

    if (state.query.trim().isEmpty) {
      return _buildMessageState(
        icon: Icons.person_search_rounded,
        title: 'Find People',
        subtitle: 'Search for users by their username.',
      );
    }

    if (state.users.isEmpty && state.status == SearchStatus.loaded) {
      return _buildMessageState(
        icon: Icons.person_off_outlined,
        title: 'No Users Found',
        subtitle: 'No users found for "${state.query}"',
      );
    }

    final currentUserId = context.select(
      (AuthenticationBloc bloc) => bloc.state.user?.id,
    );

    return ListView.builder(
      key: const PageStorageKey('users_list'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: state.users.length,
      itemBuilder: (context, index) {
        final user = state.users[index];

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 250 + (index * 60)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 15 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0F0F0), width: 0.7),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 7,
              ),
              leading: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _primaryGradient,
                ),
                child: CircleAvatar(
                  radius: 23,
                  backgroundColor: _pinkLight,
                  backgroundImage:
                      (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                      ? CachedNetworkImageProvider(user.avatarUrl!)
                      : null,
                  child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                      ? const Icon(
                          Icons.person_rounded,
                          color: _pinkDark,
                          size: 24,
                        )
                      : null,
                ),
              ),
              title: Text(
                user.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _primaryDark,
                  fontSize: 14,
                ),
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'View profile',
                  style: TextStyle(color: _subtleText, fontSize: 12),
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _pinkLight.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _pinkDark,
                  size: 14,
                ),
              ),
              onTap: () {
                if (currentUserId != user.id) {
                  context.pushNamed(
                    RouteNames.userDetail,
                    pathParameters: {'userId': user.id},
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostResultsTab(BuildContext context, SearchState state) {
    if (state.status == SearchStatus.loadingPosts) {
      return const Center(
        child: CircularProgressIndicator(color: _pinkPrimary, strokeWidth: 2.5),
      );
    }

    if (state.status == SearchStatus.failure) {
      return _buildMessageState(
        icon: Icons.error_outline_rounded,
        title: 'Something went wrong',
        subtitle: 'Failed to search: ${state.failure?.message}',
      );
    }

    final query = state.query.trim();

    if (query.isEmpty || query.length < 2) {
      return _buildMessageState(
        icon: Icons.article_outlined,
        title: 'Discover Posts',
        subtitle: 'Enter at least 2 characters to search for posts.',
      );
    }

    if (state.posts.isEmpty && state.status == SearchStatus.loaded) {
      return _buildMessageState(
        icon: Icons.search_off_rounded,
        title: 'No Posts Found',
        subtitle: 'No posts found for "${state.query}".',
      );
    }

    return ListView.builder(
      key: const PageStorageKey('posts_list'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: state.posts.length,
      itemBuilder: (context, index) {
        final post = state.posts[index];

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 250 + (index * 60)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 15 * (1 - value)),
                child: child,
              ),
            );
          },
          child: PostCard(
            post: post,
            onToggleLike: () {
              context.read<SearchBloc>().add(SearchPostLikeToggled(post: post));
            },
          ),
        );
      },
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: _pinkLight,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _pinkPrimary.withValues(alpha: 0.07),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, size: 38, color: _pinkDark),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _primaryDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _subtleText,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
