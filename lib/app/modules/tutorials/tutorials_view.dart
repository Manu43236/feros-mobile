import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'tutorials_controller.dart';

String? _youtubeId(String url) => YoutubePlayer.convertUrlToId(url);

bool _isShort(String url) => url.contains('/shorts/');

class TutorialsView extends StatelessWidget {
  const TutorialsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(TutorialsController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text('Training Tutorials',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.navy));
        }

        if (ctrl.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.mutedText),
                const SizedBox(height: 16),
                Text(ctrl.error.value,
                    style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: ctrl.fetchVideos,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (ctrl.videos.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_circle_outline, size: 64, color: AppColors.mutedText),
                const SizedBox(height: 16),
                Text('Coming Soon',
                    style: AppTextStyles.heading3.copyWith(color: AppColors.navy)),
                const SizedBox(height: 8),
                Text('Tutorial videos will be available here.',
                    style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: ctrl.videos.length,
          separatorBuilder: (context, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _VideoCard(video: ctrl.videos[i]),
        );
      }),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final dynamic video;
  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    final id = _youtubeId(video.youtubeUrl as String);
    final thumb = id != null
        ? YoutubePlayer.getThumbnail(videoId: id, quality: ThumbnailQuality.high)
        : null;

    return InkWell(
      onTap: () {
        if (id == null) return;
        Get.to(() => _VideoPlayerPage(
              title: video.featureTitle as String,
              videoId: id,
              isShort: _isShort(video.youtubeUrl as String),
            ));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumb != null)
                      CachedNetworkImage(
                        imageUrl: thumb,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: const Color(0xFFE8EDF2)),
                        errorWidget: (context, url, err) => Container(color: const Color(0xFFE8EDF2)),
                      )
                    else
                      Container(color: const Color(0xFFE8EDF2)),
                    Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(video.featureTitle as String,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: AppColors.mutedText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlayerPage extends StatefulWidget {
  final String title;
  final String videoId;
  final bool isShort;
  const _VideoPlayerPage({required this.title, required this.videoId, this.isShort = false});

  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = YoutubePlayer(
      controller: _controller,
      showVideoProgressIndicator: true,
      progressIndicatorColor: AppColors.navy,
      aspectRatio: widget.isShort ? 9 / 16 : 16 / 9,
      // hide full-screen button for Shorts — it forces landscape
      bottomActions: widget.isShort
          ? const [
              CurrentPosition(),
              ProgressBar(isExpanded: true),
              RemainingDuration(),
            ]
          : null,
    );

    final scaffold = Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text(widget.title,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        elevation: 0,
      ),
      body: Center(child: player),
    );

    // YoutubePlayerBuilder handles full-screen rotation for non-Shorts
    if (widget.isShort) return scaffold;
    return YoutubePlayerBuilder(
      player: player,
      builder: (context, p) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          title: Text(widget.title,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          elevation: 0,
        ),
        body: Center(child: p),
      ),
    );
  }
}
