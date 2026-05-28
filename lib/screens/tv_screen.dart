import 'package:al_medynah/model/tv_models.dart';
import 'package:al_medynah/screens/video_player_screen.dart';
import 'package:al_medynah/services/tv_service.dart';
import 'package:flutter/material.dart';

class TvScreen extends StatefulWidget {
  const TvScreen({super.key});

  @override
  State<TvScreen> createState() => _TvScreenState();
}

class _TvScreenState extends State<TvScreen> {
  final TvService _tvService = TvService();

  List<LiveTvChannel> _liveChannels = [];
  List<VideoType> _videoTypes = [];
  List<ReciterVideos> _allVideos = [];
  List<ReciterVideos> _filteredVideos = [];
  bool _isLoading = true;
  int? _selectedTypeId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _tvService.fetchLiveTV(),
      _tvService.fetchVideoTypes(),
      _tvService.fetchVideos(),
    ]);
    if (mounted) {
      setState(() {
        _liveChannels = results[0] as List<LiveTvChannel>;
        _videoTypes = results[1] as List<VideoType>;
        _allVideos = results[2] as List<ReciterVideos>;
        _filteredVideos = _allVideos;
        _isLoading = false;
      });
    }
  }

  void _filterByType(int? typeId) {
    setState(() {
      _selectedTypeId = typeId;
      if (typeId == null) {
        _filteredVideos = _allVideos;
      } else {
        _filteredVideos = _allVideos
            .map(
              (r) => ReciterVideos(
                id: r.id,
                reciterName: r.reciterName,
                videos: r.videos.where((v) => v.videoType == typeId).toList(),
              ),
            )
            .where((r) => r.videos.isNotEmpty)
            .toList();
      }
    });
  }

  void _playVideo(String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(url: url, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          title: const Text('التلفزيون'),
          backgroundColor: const Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFB8964E)),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _buildSectionTitle('📺', 'البث المباشر'),
                  const SizedBox(height: 12),
                  _buildLiveTvRow(),
                  const SizedBox(height: 24),
                  if (_videoTypes.isNotEmpty) ...[
                    _buildSectionTitle('📂', 'التصنيفات'),
                    const SizedBox(height: 12),
                    _buildVideoTypeChips(),
                    const SizedBox(height: 24),
                  ],
                  _buildSectionTitle('🎬', 'المرئيات'),
                  const SizedBox(height: 12),
                  if (_filteredVideos.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'لا توجد فيديوهات في هذا التصنيف',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    ..._filteredVideos.map(_buildReciterSection),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String emoji, String title) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFB8964E),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveTvRow() {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _liveChannels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final channel = _liveChannels[index];
          return GestureDetector(
            onTap: () => _playVideo(channel.url, channel.name),
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3E2A0F), Color(0xFF5C3D1E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFB8964E).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.live_tv, color: Color(0xFFB8964E), size: 32),
                  const SizedBox(height: 8),
                  Text(
                    channel.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'مباشر',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoTypeChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _videoTypes.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == 0
              ? _selectedTypeId == null
              : _videoTypes[index - 1].id == _selectedTypeId;
          final label = index == 0 ? 'الكل' : _videoTypes[index - 1].name;

          return GestureDetector(
            onTap: () =>
                _filterByType(index == 0 ? null : _videoTypes[index - 1].id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFB8964E)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFB8964E)
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReciterSection(ReciterVideos reciter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 4),
            child: Text(
              reciter.reciterName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: reciter.videos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final video = reciter.videos[index];
                return GestureDetector(
                  onTap: () => _playVideo(video.videoUrl, reciter.reciterName),
                  child: Container(
                    width: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Image.network(
                            video.thumbnailUrl,
                            width: 150,
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: Colors.white.withValues(alpha: 0.1),
                              child: const Icon(
                                Icons.movie,
                                color: Colors.white54,
                                size: 40,
                              ),
                            ),
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: Colors.white.withValues(alpha: 0.05),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFB8964E),
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Colors.black54],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          const Center(
                            child: Icon(
                              Icons.play_circle_fill,
                              color: Color(0xFFB8964E),
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
