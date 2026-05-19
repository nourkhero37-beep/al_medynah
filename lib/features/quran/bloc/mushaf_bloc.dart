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

  MushafBloc({required this.repository}) : super(const MushafState()) {
    on<MushafInitialLoad>(_onInitialLoad);
    on<MushafPageChanged>(_onPageChanged);
    on<MushafWordTapped>(_onWordTapped);
    on<MushafPlayTapped>(_onPlayTapped);
    on<MushafPositionUpdated>(_onPositionUpdated);
    on<MushafStopTapped>(_onStopTapped);
  }

  Future<void> _onStopTapped(
    MushafStopTapped event,
    Emitter<MushafState> emit,
  ) async {
    await repository.stopAudio();
    _positionSubscription?.cancel();
    emit(state.copyWith(isPlaying: false, selectedVerseKey: null));
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

    _playerStateSubscription?.cancel();
    _playerStateSubscription = repository.playerStateStream.listen((
      playerState,
    ) {
      if (!isClosed &&
          playerState.processingState == ProcessingState.completed) {
        // ✅ فقط عند انتهاء التشغيل كاملاً
        add(
          const MushafPositionUpdated(
            position: Duration.zero,
            verseTimings: {},
          ),
        );
      }
    });
  }

  Future<void> _onPageChanged(
    MushafPageChanged event,
    Emitter<MushafState> emit,
  ) async {
    emit(state.copyWith(currentPage: event.page));
    await repository.preloadPages(event.page);
    emit(state.copyWith(pagesCache: repository.pagesCache));
  }

  void _onWordTapped(MushafWordTapped event, Emitter<MushafState> emit) {
    final newSelectedVerseKey = state.selectedVerseKey == event.verseKey
        ? null
        : event.verseKey;
    emit(state.copyWith(selectedVerseKey: newSelectedVerseKey));
  }

  Future<void> _onPlayTapped(
    MushafPlayTapped event,
    Emitter<MushafState> emit,
  ) async {
    if (state.selectedVerseKey == null) {
      emit(state.copyWith(errorMessage: 'اضغط على آية أولاً لتشغيلها'));
      return;
    }

    if (state.isPlaying) {
      await repository.stopAudio();
      _positionSubscription?.cancel();
      emit(state.copyWith(isPlaying: false));
      return;
    }

    final surahNumber =
        int.tryParse(state.selectedVerseKey!.split(':')[0]) ?? 1;

    final downloaded = await repository.isSurahDownloaded(surahNumber);
    if (!downloaded) {
      emit(
        state.copyWith(errorMessage: 'يجب تحميل القارئ أولاً من صفحة القراء'),
      );
      return;
    }

    final timings = await repository.fetchVerseTimings(surahNumber);
    emit(state.copyWith(verseTimings: timings));

    // ✅ نجيب وقت بداية الآية المحددة
    final seekToMs = timings[state.selectedVerseKey]?[0];

    _positionSubscription?.cancel();
    _positionSubscription = repository.positionStream.listen((position) {
      if (!isClosed) {
        add(MushafPositionUpdated(position: position, verseTimings: timings));
      }
    });

    // ✅ نمرر وقت البداية
    await repository.playVerse(state.selectedVerseKey!, seekToMs: seekToMs);
    emit(state.copyWith(isPlaying: true));
  }

  void _onPositionUpdated(
    MushafPositionUpdated event,
    Emitter<MushafState> emit,
  ) {
    if (event.verseTimings.isEmpty) {
      emit(state.copyWith(isPlaying: false));
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
      emit(state.copyWith(selectedVerseKey: currentVerseKey));
    }

    if (state.errorMessage != null) {
      emit(state.copyWith(errorMessage: null));
    }
  }

  @override
  Future<void> close() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    repository.dispose();
    return super.close();
  }
}
