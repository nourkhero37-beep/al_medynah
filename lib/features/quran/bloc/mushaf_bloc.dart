import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import '../repository/mushaf_repository.dart';
import 'mushaf_event.dart';
import 'mushaf_state.dart';

class MushafBloc extends Bloc<MushafEvent, MushafState> {
  final MushafRepository repository;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  MushafBloc({required this.repository}) : super(const MushafState()) {
    on<MushafInitialLoad>(_onInitialLoad);
    on<MushafPageChanged>(_onPageChanged);
    on<MushafWordTapped>(_onWordTapped);
    on<MushafPlayTapped>(_onPlayTapped);
    on<MushafPauseTapped>(_onPauseTapped);
    on<MushafPositionUpdated>(_onPositionUpdated);
    on<MushafDurationUpdated>(_onDurationUpdated); // âœ… Ø¬Ø¯ÙŠØ¯
    on<MushafStopTapped>(_onStopTapped);
    on<MushafCacheUpdate>(_onCacheUpdate);
  }

  // âœ… Ø¬Ø¯ÙŠØ¯: handler Ù…Ù†ÙØµÙ„ Ù„Ù„Ù€ duration â€” Ø¨Ø¯Ù„ emit Ø¯Ø§Ø®Ù„ listener Ù…Ø¨Ø§Ø´Ø±Ø©
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
    if (state.isPlaying) {
      await repository.pauseAudio();
      emit(state.copyWith(isPlaying: false, isPaused: true));
    } else if (state.isPaused) {
      await repository.resumeAudio();
      emit(state.copyWith(isPlaying: true, isPaused: false));
    }
  }

  Future<void> _onStopTapped(
    MushafStopTapped event,
    Emitter<MushafState> emit,
  ) async {
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
    emit(
      state.copyWith(
        currentPage: event.initialPage,
        selectedVerseKey: event.highlightedVerseKey,
        isLoading: true,
      ),
    );

    await repository.preloadPages(event.initialPage);
    emit(state.copyWith(pagesCache: repository.pagesCache, isLoading: false));

    // âœ… playerState listener â€” ÙŠØ³ØªØ®Ø¯Ù… add() Ù…Ø´ emit() Ù…Ø¨Ø§Ø´Ø±Ø©
    _playerStateSubscription?.cancel();
    _playerStateSubscription = repository.playerStateStream.listen((
      playerState,
    ) {
      if (!isClosed &&
          playerState.processingState == ProcessingState.completed) {
        add(
          const MushafPositionUpdated(
            position: Duration.zero,
            verseTimings: {},
          ),
        );
      }
    });

    // âœ… Ù…ØµØ­Ø­: duration subscription ÙŠØ³ØªØ®Ø¯Ù… add() Ø¨Ø¯Ù„ emit() Ù…Ø¨Ø§Ø´Ø±Ø©
    _durationSubscription?.cancel();
    _durationSubscription = repository.durationStream.listen((duration) {
      if (!isClosed && duration != null) {
        add(MushafDurationUpdated(duration)); // âœ… add() ÙˆÙ„ÙŠØ³ emit()
      }
    });
  }

  Future<void> _onPageChanged(
    MushafPageChanged event,
    Emitter<MushafState> emit,
  ) async {
    emit(state.copyWith(currentPage: event.page, pagesCache: repository.pagesCache));
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

  @override
  Future<void> close() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    repository.dispose();
    return super.close();
  }
}

