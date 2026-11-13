import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/search_account.dart';
import '../../domain/entities/search_category.dart';
import '../../domain/entities/search_data.dart';
import '../../domain/entities/search_post.dart';
import 'search_providers.dart';

class SearchState {
  const SearchState({
    this.isLoading = true,
    this.failure,
    this.data,
    this.query = '',
    this.selectedCategory = SearchCategory.all,
  });

  final bool isLoading;
  final Failure? failure;
  final SearchData? data;
  final String query;
  final SearchCategory selectedCategory;

  bool get isDefaultView =>
      query.trim().isEmpty && selectedCategory == SearchCategory.all;

  List<SearchAccount> get filteredAccounts {
    final accounts = data?.accounts ?? const <SearchAccount>[];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return accounts.where((a) {
      final hay = '${a.handle} ${a.name}'.toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  List<SearchPost> get filteredPosts {
    final posts = data?.posts ?? const <SearchPost>[];
    final q = query.trim().toLowerCase();
    return posts.where((post) {
      final matchesCat =
          selectedCategory == SearchCategory.all ||
          post.category == selectedCategory;
      if (!matchesCat) return false;
      if (q.isEmpty) return true;
      final hay =
          '${post.caption} ${post.place} ${post.authorName} ${post.authorHandle}'
              .toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  SearchState copyWith({
    bool? isLoading,
    Failure? failure,
    bool clearFailure = false,
    SearchData? data,
    String? query,
    SearchCategory? selectedCategory,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
      data: data ?? this.data,
      query: query ?? this.query,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class SearchController extends Notifier<SearchState> {
  @override
  SearchState build() {
    Future.microtask(load);
    return const SearchState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    try {
      final data = await ref.read(loadSearchDataProvider).call();
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, data: data, clearFailure: true);
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, failure: failure);
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, failure: const UnknownFailure());
    }
  }

  void setQuery(String value) {
    if (state.query == value) return;
    state = state.copyWith(query: value);
  }

  void clearQuery() {
    if (state.query.isEmpty) return;
    state = state.copyWith(query: '');
  }

  void selectCategory(SearchCategory category) {
    if (state.selectedCategory == category) return;
    state = state.copyWith(selectedCategory: category);
  }
}

final searchControllerProvider =
    NotifierProvider.autoDispose<SearchController, SearchState>(
      SearchController.new,
    );
