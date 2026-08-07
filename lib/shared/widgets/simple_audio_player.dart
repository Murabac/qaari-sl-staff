import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:qaari_sl_staff/core/theme/app_colors.dart';

class SimpleAudioPlayer extends StatefulWidget {
  const SimpleAudioPlayer({
    super.key,
    required this.url,
    this.title = 'Audio',
  });

  final String url;
  final String title;

  @override
  State<SimpleAudioPlayer> createState() => _SimpleAudioPlayerState();
}

class _SimpleAudioPlayerState extends State<SimpleAudioPlayer> {
  late final AudioPlayer _player;
  var _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _load();
  }

  Future<void> _load() async {
    try {
      await _player.setUrl(widget.url);
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load audio');
    }
  }

  @override
  void didUpdateWidget(covariant SimpleAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _ready = false;
      _error = null;
      _load();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Text(_error!, style: const TextStyle(color: AppColors.danger));
    }
    if (!_ready) {
      return const LinearProgressIndicator();
    }

    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.filled(
                  onPressed: () => playing ? _player.pause() : _player.play(),
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                ),
                Expanded(
                  child: StreamBuilder<Duration>(
                    stream: _player.positionStream,
                    builder: (context, posSnap) {
                      final pos = posSnap.data ?? Duration.zero;
                      final total = _player.duration ?? Duration.zero;
                      final maxMs = total.inMilliseconds < 1
                          ? 1.0
                          : total.inMilliseconds.toDouble();
                      final valueMs = pos.inMilliseconds
                          .toDouble()
                          .clamp(0.0, maxMs)
                          .toDouble();
                      return Column(
                        children: [
                          Slider(
                            value: valueMs,
                            max: maxMs,
                            onChanged: (v) =>
                                _player.seek(Duration(milliseconds: v.round())),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(pos), style: const TextStyle(fontSize: 12)),
                              Text(_fmt(total), style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
