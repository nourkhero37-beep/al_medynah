import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repository/mushaf_repository.dart';
import 'mushaf_event.dart';
import 'mushaf_state.dart';

class MushafBloc extends Bloc<MushafEvent, MushafState> {
  final MushafRepository repository;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  bool _isHandlingCompletion = false;

  MushafBloc({required this.repository}) : super(const MushafState()) {
    on<MushafInitialLoad>(_onInitialLoad);
    on<MushafPageChanged>(_onPageChanged);
    on<MushafWordTapped>(_onWordTapped);
    on<MushafPlayTapped>(_onPlayTapped);
    on<MushafPauseTapped>(_onPauseTapped);
    on<MushafPositionUpdated>(_onPositionUpdated);
    on<MushafDurationUpdated>(_onDurationUpdated);
    on<MushafStopTapped>(_onStopTapped);
    on<MushafCacheUpdate>(_onCacheUpdate);
    on<MushafFontSizeChanged>(_onFontSizeChanged);
    on<MushafDarkModeToggled>(_onDarkModeToggled);
    on<MushafTextColorChanged>(_onTextColorChanged);
    on<MushafAutoAdvanceSurah>(_onAutoAdvanceSurah);
  }

  void _onDurationUpdated(
    MushafDurationUpdated event,
    Emitter<MushafState> emit,
  ) {
    emit(state.copyWith(totalDuration: event.duration));
  }

  Future<void> _onPauseTapped(
    MushafPauseTapped event,
    Emitter<MushafState> emit,
  ) async {
    _isHandlingCompletion = false;

    if (state.isPlaying) {
      await repository.pauseAudio();
      emit(state.copyWith(isPlaying: false, isPaused: true));
    } else if (state.isPaused) {
      await repository.resumeAudio();
      emit(state.copyWith(isPlaying: true, isPaused: false));
    } else {
      if (state.selectedVerseKey != null) {
        add(const MushafPlayTapped());
      }
    }
  }

  Future<void> _onStopTapped(
    MushafStopTapped event,
    Emitter<MushafState> emit,
  ) async {
    _isHandlingCompletion = false;
    await repository.stopAudio();
    _positionSubscription?.cancel();
    emit(
      state.copyWith(
        isPlaying: false,
        isPaused: false,
        selectedVerseKey: null,
        currentPosition: Duration.zero,
      ),
    );
  }

  void _onCacheUpdate(
    MushafCacheUpdate event,
    Emitter<MushafState> emit,
  ) {
    emit(state.copyWith(pagesCache: repository.pagesCache));
  }

  Future<void> _onInitialLoad(
    MushafInitialLoad event,
    Emitter<MushafState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final savedColor = prefs.getInt('quran_text_color') ?? 0xDD000000;
    final savedDarkMode = prefs.getBool('quran_dark_mode') ?? false;

    emit(
      state.copyWith(
        currentPage: event.initialPage,
        selectedVerseKey: event.highlightedVerseKey,
        isLoading: true,
        textColor: savedColor,
        isDarkMode: savedDarkMode,
      ),
    );

    await repository.preloadPages(event.initialPage);
    emit(state.copyWith(pagesCache: repository.pagesCache, isLoading: false));

    _playerStateSubscription?.cancel();
    _playerStateSubscription = repository.playerStateStream.listen((
      playerState,
    ) {
      if (!isClosed &&
          playerState.processingState == ProcessingState.completed &&
          !_isHandlingCompletion) {
        // Position guard: only consider completion legitimate if
        // we're near the end of the audio (filters false events on Windows)
        final timings = state.verseTimings;
        if (timings.isNotEmpty) {
          final maxEndMs = timings.values
              .expand((list) => list)
              .reduce((a, b) => a > b ? a : b);
          if (repository.currentPosition.inMilliseconds < maxEndMs - 500) {
            return;
          }
        }
        _isHandlingCompletion = true;
        final currentVerseKey = state.selectedVerseKey;
        if (currentVerseKey != null) {
          final currentSurah = int.tryParse(currentVerseKey.split(':')[0]) ?? 0;
          final nextSurah = currentSurah + 1;
          if (nextSurah <= 114) {
            unawaited(_tryAdvanceSurah(nextSurah));
            return;
          }
        }
        _isHandlingCompletion = false;
        add(
          const MushafPositionUpdated(
            position: Duration.zero,
            verseTimings: {},
          ),
        );
      }
    });

    _durationSubscription?.cancel();
    _durationSubscription = repository.durationStream.listen((duration) {
      if (!isClosed && duration != null) {
        add(MushafDurationUpdated(duration));
      }
    });
  }

  Future<void> _onPageChanged(
    MushafPageChanged event,
    Emitter<MushafState> emit,
  ) async {
    emit(state.copyWith(currentPage: event.page, pagesCache: repository.pagesCache));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_read_page', event.page);
    unawaited(repository.preloadPages(event.page).then((_) {
      if (!isClosed) add(const MushafCacheUpdate());
    }));
  }

  void _onWordTapped(MushafWordTapped event, Emitter<MushafState> emit) {
    final newKey = state.selectedVerseKey == event.verseKey
        ? null
        : event.verseKey;
    emit(state.copyWith(selectedVerseKey: newKey));
  }

  Future<void> _onPlayTapped(
    MushafPlayTapped event,
    Emitter<MushafState> emit,
  ) async {
    _isHandlingCompletion = false;

    if (state.selectedVerseKey == null) {
      emit(state.copyWith(errorMessage: 'mushaf.error.tapFirst'));
      return;
    }

    final surahNumber =
        int.tryParse(state.selectedVerseKey!.split(':')[0]) ?? 1;
    final downloaded = await repository.isSurahDownloaded(surahNumber);
    if (!downloaded) {
      emit(
        state.copyWith(errorMessage: 'mushaf.error.noReciter'),
      );
      return;
    }

    final timings = await repository.fetchVerseTimings(surahNumber);
    emit(state.copyWith(verseTimings: timings));

    final seekToMs = timings[state.selectedVerseKey]?[0];

    _positionSubscription?.cancel();
    _positionSubscription = repository.positionStream.listen((position) {
      if (!isClosed) {
        add(MushafPositionUpdated(position: position, verseTimings: timings));
      }
    });

    emit(state.copyWith(isPlaying: true, isPaused: false));

    await repository.playVerse(state.selectedVerseKey!, seekToMs: seekToMs);
  }

  void _onPositionUpdated(
    MushafPositionUpdated event,
    Emitter<MushafState> emit,
  ) {
    // Guard: skip stale events from old position subscription after auto-advance
    if (state.verseTimings.isNotEmpty && event.verseTimings.isNotEmpty &&
        state.verseTimings.keys.first != event.verseTimings.keys.first) {
      return;
    }

    // Early exit if no timings loaded yet
    if (event.verseTimings.isEmpty) {
      emit(
        state.copyWith(
          isPlaying: false,
          isPaused: false,
          currentPosition: Duration.zero,
        ),
      );
      return;
    }

    // Position-based completion fallback (for platforms where ProcessingState.completed is unreliable)
    final maxEndMs = event.verseTimings.values
        .expand((list) => list)
        .reduce((a, b) => a > b ? a : b);
    if (!_isHandlingCompletion &&
        state.isPlaying &&
        maxEndMs > 500 &&
        event.position.inMilliseconds >= maxEndMs - 500) {
      _isHandlingCompletion = true;
      final vsKey = state.selectedVerseKey;
      if (vsKey != null) {
        final surah = int.tryParse(vsKey.split(':')[0]) ?? 0;
        if (surah > 0 && surah < 114) {
          unawaited(_tryAdvanceSurah(surah + 1));
          return;
        }
      }
      _isHandlingCompletion = false;
    }

    final ms = event.position.inMilliseconds;
    String? currentVerseKey;

    for (final entry in event.verseTimings.entries) {
      final start = entry.value[0];
      final end = entry.value[1];
      if (ms >= start && ms < end) {
        currentVerseKey = entry.key;
        break;
      }
    }

    if (currentVerseKey != null && state.selectedVerseKey != currentVerseKey) {
      emit(
        state.copyWith(
          selectedVerseKey: currentVerseKey,
          currentPosition: event.position,
        ),
      );
    } else {
      emit(state.copyWith(currentPosition: event.position));
    }

    if (state.errorMessage != null) {
      emit(state.copyWith(errorMessage: null));
    }
  }

  void _onFontSizeChanged(
    MushafFontSizeChanged event,
    Emitter<MushafState> emit,
  ) {
    emit(state.copyWith(fontScale: event.fontScale));
  }

  Future<void> _onDarkModeToggled(
    MushafDarkModeToggled event,
    Emitter<MushafState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('quran_dark_mode', event.isDarkMode);
    emit(state.copyWith(isDarkMode: event.isDarkMode));
  }

  Future<void> _onTextColorChanged(
    MushafTextColorChanged event,
    Emitter<MushafState> emit,
  ) async {
    final color = ui.Color(event.colorValue);
    final luminance = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
    final autoDarkMode = luminance > 0.6;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quran_text_color', event.colorValue);
    await prefs.setBool('quran_dark_mode', autoDarkMode);

    emit(state.copyWith(
      textColor: event.colorValue,
      isDarkMode: autoDarkMode,
    ));
  }

  Future<void> _tryAdvanceSurah(int nextSurah) async {
    if (nextSurah > 114) {
      _isHandlingCompletion = false;
      return;
    }
    final downloaded = await repository.isSurahDownloaded(nextSurah);
    if (!downloaded) {
      _isHandlingCompletion = false;
      return;
    }
    if (!isClosed) add(MushafAutoAdvanceSurah(nextSurah));
  }

  Future<void> _onAutoAdvanceSurah(
    MushafAutoAdvanceSurah event,
    Emitter<MushafState> emit,
  ) async {
    _isHandlingCompletion = false;

    final firstVerseKey = '${event.surahNumber}:1';
    _positionSubscription?.cancel();

    final timings = await repository.fetchVerseTimings(event.surahNumber);
    final seekToMs = timings[firstVerseKey]?[0];

    _positionSubscription = repository.positionStream.listen((position) {
      if (!isClosed) {
        add(MushafPositionUpdated(position: position, verseTimings: timings));
      }
    });

    emit(state.copyWith(
      selectedVerseKey: firstVerseKey,
      verseTimings: timings,
      isPlaying: true,
      isPaused: false,
      currentPosition: Duration.zero,
    ));

    await repository.playVerse(firstVerseKey, seekToMs: seekToMs);
  }

  @override
  Future<void> close() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    repository.dispose();
    return super.close();
  }
}


