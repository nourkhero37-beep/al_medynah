import 'package:equatable/equatable.dart';

class MushafState extends Equatable {
  final int currentPage;
  final String? selectedVerseKey;
  final Map<int, Map<String, dynamic>> pagesCache;
  final bool isPlaying;
  final bool isPaused; // ✅ جديد
  final Map<String, List<int>> verseTimings;
  final bool isLoading;
  final String? errorMessage;
  final Duration currentPosition; // ✅ جديد
  final Duration totalDuration; // ✅ جديد

  const MushafState({
    this.currentPage = 1,
    this.selectedVerseKey,
    this.pagesCache = const {},
    this.isPlaying = false,
    this.isPaused = false,
    this.verseTimings = const {},
    this.isLoading = false,
    this.errorMessage,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
  });

  // ✅ sentinel pattern لحل مشكلة selectedVerseKey = null
  static const _sentinel = Object();

  MushafState copyWith({
    int? currentPage,
    Object? selectedVerseKey = _sentinel,
    Map<int, Map<String, dynamic>>? pagesCache,
    bool? isPlaying,
    bool? isPaused,
    Map<String, List<int>>? verseTimings,
    bool? isLoading,
    String? errorMessage,
    Duration? currentPosition,
    Duration? totalDuration,
  }) {
    return MushafState(
      currentPage: currentPage ?? this.currentPage,
      selectedVerseKey: selectedVerseKey == _sentinel
          ? this.selectedVerseKey
          : selectedVerseKey as String?,
      pagesCache: pagesCache ?? this.pagesCache,
      isPlaying: isPlaying ?? this.isPlaying,
      isPaused: isPaused ?? this.isPaused,
      verseTimings: verseTimings ?? this.verseTimings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }

  @override
  List<Object?> get props => [
    currentPage,
    selectedVerseKey,
    pagesCache,
    isPlaying,
    isPaused,
    verseTimings,
    isLoading,
    errorMessage,
    currentPosition,
    totalDuration,
  ];
}
