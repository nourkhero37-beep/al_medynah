import 'package:equatable/equatable.dart';

class MushafState extends Equatable {
  final int currentPage;
  final String? selectedVerseKey;
  final Map<int, Map<String, dynamic>> pagesCache;
  final bool isPlaying;
  final Map<String, List<int>> verseTimings;
  final bool isLoading;
  final String? errorMessage;

  const MushafState({
    this.currentPage = 1,
    this.selectedVerseKey,
    this.pagesCache = const {},
    this.isPlaying = false,
    this.verseTimings = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  MushafState copyWith({
    int? currentPage,
    String? selectedVerseKey,
    Map<int, Map<String, dynamic>>? pagesCache,
    bool? isPlaying,
    Map<String, List<int>>? verseTimings,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MushafState(
      currentPage: currentPage ?? this.currentPage,
      selectedVerseKey: selectedVerseKey ?? this.selectedVerseKey,
      pagesCache: pagesCache ?? this.pagesCache,
      isPlaying: isPlaying ?? this.isPlaying,
      verseTimings: verseTimings ?? this.verseTimings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    currentPage,
    selectedVerseKey,
    pagesCache,
    isPlaying,
    verseTimings,
    isLoading,
    errorMessage,
  ];
}
