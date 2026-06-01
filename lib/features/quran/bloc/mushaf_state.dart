import 'package:equatable/equatable.dart';

class MushafState extends Equatable {
  final int currentPage;
  final String? selectedVerseKey;
  final Map<int, Map<String, dynamic>> pagesCache;
  final bool isPlaying;
  final bool isPaused;
  final Map<String, List<int>> verseTimings;
  final bool isLoading;
  final String? errorMessage;
  final Duration currentPosition;
  final Duration totalDuration;
  final double fontScale;
  final bool isDarkMode;
  final int textColor;

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
    this.fontScale = 1.0,
    this.isDarkMode = false,
    this.textColor = 0xDD000000,
  });

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
    double? fontScale,
    bool? isDarkMode,
    int? textColor,
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
      fontScale: fontScale ?? this.fontScale,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      textColor: textColor ?? this.textColor,
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
    fontScale,
    isDarkMode,
    textColor,
  ];
}
