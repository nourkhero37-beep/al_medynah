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

class MushafPauseTapped extends MushafEvent {
  const MushafPauseTapped();
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

class MushafDurationUpdated extends MushafEvent {
  final Duration duration;
  const MushafDurationUpdated(this.duration);

  @override
  List<Object?> get props => [duration];
}

class MushafCacheUpdate extends MushafEvent {
  const MushafCacheUpdate();
}

class MushafFontSizeChanged extends MushafEvent {
  final double fontScale;
  const MushafFontSizeChanged(this.fontScale);

  @override
  List<Object?> get props => [fontScale];
}

class MushafDarkModeToggled extends MushafEvent {
  final bool isDarkMode;
  const MushafDarkModeToggled(this.isDarkMode);

  @override
  List<Object?> get props => [isDarkMode];
}

class MushafAutoAdvanceSurah extends MushafEvent {
  final int surahNumber;
  const MushafAutoAdvanceSurah(this.surahNumber);

  @override
  List<Object?> get props => [surahNumber];
}

class MushafTextColorChanged extends MushafEvent {
  final int colorValue;
  const MushafTextColorChanged(this.colorValue);

  @override
  List<Object?> get props => [colorValue];
}
