import 'package:equatable/equatable.dart';

abstract class MushafEvent extends Equatable {
  const MushafEvent();

  @override
  List<Object?> get props => [];
}

class MushafInitialLoad extends MushafEvent {
  final int initialPage;
  final String? highlightedVerseKey;

  const MushafInitialLoad({
    required this.initialPage,
    this.highlightedVerseKey,
  });

  @override
  List<Object?> get props => [initialPage, highlightedVerseKey];
}

class MushafPageChanged extends MushafEvent {
  final int page;

  const MushafPageChanged(this.page);

  @override
  List<Object?> get props => [page];
}

class MushafWordTapped extends MushafEvent {
  final String? verseKey;

  const MushafWordTapped(this.verseKey);

  @override
  List<Object?> get props => [verseKey];
}

class MushafPlayTapped extends MushafEvent {
  const MushafPlayTapped();
}

class MushafStopTapped extends MushafEvent {
  const MushafStopTapped();
}

class MushafPositionUpdated extends MushafEvent {
  final Duration position;
  final Map<String, List<int>> verseTimings;

  const MushafPositionUpdated({
    required this.position,
    required this.verseTimings,
  });

  @override
  List<Object?> get props => [position, verseTimings];
}
