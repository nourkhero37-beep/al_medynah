import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:al_medynah/model/reciters_model.dart';
import 'package:al_medynah/model/surah_model.dart';
import 'package:al_medynah/services/audio_manager_api.dart';
import 'package:al_medynah/features/quran/bloc/mushaf_bloc.dart';
import 'package:al_medynah/features/quran/bloc/mushaf_state.dart';
import 'package:al_medynah/features/quran/bloc/mushaf_event.dart';
import 'package:al_medynah/l10n/app_localizations.dart';

class AudioPlayerBar extends StatefulWidget {
  const AudioPlayerBar({super.key});

  @override
  State<AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends State<AudioPlayerBar> {
  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:$m:$s';
    }
    return '$m:$s';
  }

  Future<void> _showReciterSheet() async {
    final tr = AppLocalizations.of(context).tr;
    final audioManager = AudioManager();
    final currentId = audioManager.currentReciterId;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return FutureBuilder<List<RecitersModel>>(
          future: AudioManager().fetchReciters(),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return SizedBox(
                height: 200,
                child: Center(child: Text(tr('reciter.error.load'))),
              );
            }

            final reciters = snapshot.data!;

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.85,
              expand: false,
              builder: (ctx, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        children: [
                          Text(
                            tr('mushaf.reciter.select'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'GE SS Two',
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: reciters.length,
                        itemBuilder: (ctx, index) {
                          final reciter = reciters[index];
                          final rid = reciter.id.toString();
                          final isSelected = rid == currentId;

                          return ListTile(
                            leading: Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected ? const Color(0xFF2493B4) : null,
                            ),
                            title: Text(
                              reciter.nameArabic,
                              style: TextStyle(
                                fontFamily: 'GE SS Two',
                                fontWeight: isSelected ? FontWeight.bold : null,
                                color: isSelected ? const Color(0xFF2493B4) : null,
                              ),
                            ),
                            subtitle: Text(reciter.rewaya),
                            trailing: isSelected
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2493B4).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tr('reciter.badge.selected'),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF2493B4),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: () async {
                              await audioManager.saveSelectedReciter(
                                rid,
                                reciter.serverUrl,
                                reciter.nameArabic,
                              );
                              if (ctx.mounted) {
                                setState(() {});
                                Navigator.pop(ctx);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildReciterRow() {
    final name = AudioManager().currentReciterName;
    if (name == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _showReciterSheet,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(Icons.record_voice_over_rounded, size: 14, color: Colors.white54),
            const SizedBox(width: 4),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontFamily: 'GE SS Two',
              ),
            ),
            const Spacer(),
            Icon(Icons.expand_more_rounded, size: 16, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MushafBloc, MushafState>(
      builder: (context, state) {
        final bool isActive = state.isPlaying || state.isPaused;
        final bool show = isActive || state.selectedVerseKey != null;

        final position = state.currentPosition;
        final total = state.totalDuration;
        final double progress = (total.inMilliseconds > 0)
            ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

        String surahName = '';
        String ayahNumber = '';
        if (state.selectedVerseKey != null) {
          final parts = state.selectedVerseKey!.split(':');
          final surahId = int.tryParse(parts[0]) ?? 0;
          ayahNumber = parts.length > 1 ? parts[1] : '';
          if (surahId >= 1 && surahId <= surahList.length) {
            surahName = surahList[surahId - 1].nameArabic;
          }
        }

        return AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: Container(
            height: show ? null : 0,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2493B4), Color(0xFF1E7FA0)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildReciterRow(),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2.5,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                        activeTrackColor: const Color(0xFF2493B4),
                        inactiveTrackColor: Colors.white24,
                        thumbColor: const Color(0xFF2493B4),
                        overlayColor: const Color(0x332493B4),
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: (val) {
                          if (total.inMilliseconds > 0) {
                            final seekMs = (val * total.inMilliseconds).toInt();
                            AudioManager().player.seek(
                              Duration(milliseconds: seekMs),
                            );
                          }
                        },
                      ),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: Text(
                            _formatDuration(position),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontFamily: 'GE SS Two',
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (isActive)
                          GestureDetector(
                            onTap: () => context.read<MushafBloc>().add(
                              const MushafStopTapped(),
                            ),
                            child: const Icon(
                              Icons.stop_rounded,
                              color: Colors.white54,
                              size: 28,
                            ),
                          ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            if (!isActive) {
                              context.read<MushafBloc>().add(
                                const MushafPlayTapped(),
                              );
                            } else {
                              context.read<MushafBloc>().add(
                                const MushafPauseTapped(),
                              );
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF2493B4), Color(0xFF1E7FA0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              (state.isPlaying && !state.isPaused)
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              surahName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'GE SS Two',
                              ),
                            ),
                            if (ayahNumber.isNotEmpty)
                              Text(
                                '\u0622\u064A\u0629 $ayahNumber',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  fontFamily: 'GE SS Two',
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 56,
                          child: Text(
                            _formatDuration(total),
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontFamily: 'GE SS Two',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}