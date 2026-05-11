import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/frame.dart';
import '../models/shot.dart';
import '../services/firestore_service.dart';
import '../widgets/error_state.dart';
import '../widgets/info_chip.dart';
import 'shot_add_screen.dart';

class FrameDetailScreen extends StatelessWidget {
  const FrameDetailScreen({required this.frameId, super.key});

  final String frameId;

  Future<void> _deleteFrame(
    BuildContext context,
    FirestoreService firestoreService,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프레임 삭제'),
        content: const Text('프레임과 연결된 기록 목록이 삭제됩니다. 계속할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await firestoreService.deleteFrame(frameId);

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제에 실패했습니다: ${error.message ?? error.code}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<Frame?>(
      stream: firestoreService.watchFrame(frameId),
      builder: (context, frameSnapshot) {
        final frame = frameSnapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: Text(frame?.name ?? '프레임'),
            actions: [
              IconButton(
                tooltip: '프레임 삭제',
                onPressed: frame == null
                    ? null
                    : () => _deleteFrame(context, firestoreService),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          floatingActionButton: frame == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => ShotAddScreen(frameId: frameId),
                  ),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('촬영 기록'),
                ),
          body: SafeArea(
            child: Builder(
              builder: (context) {
                if (frameSnapshot.hasError) {
                  return ErrorState(
                    title: '프레임을 불러오지 못했어요',
                    message: '${frameSnapshot.error}',
                  );
                }

                if (frameSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (frame == null) {
                  return const ErrorState(
                    title: '프레임이 없습니다',
                    message: '삭제되었거나 접근할 수 없는 프레임입니다.',
                  );
                }

                return StreamBuilder<List<Shot>>(
                  stream: firestoreService.watchShots(frameId),
                  builder: (context, shotSnapshot) {
                    if (shotSnapshot.hasError) {
                      return ErrorState(
                        title: '촬영 기록을 불러오지 못했어요',
                        message: '${shotSnapshot.error}',
                      );
                    }

                    final shots = shotSnapshot.data ?? <Shot>[];

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                      children: [
                        FrameDetailHeader(frame: frame),
                        const SizedBox(height: 24),
                        Text(
                          '촬영 기록',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        if (shotSnapshot.connectionState == ConnectionState.waiting)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (shots.isEmpty)
                          const EmptyShotState()
                        else
                          ...shots.map(
                            (shot) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ShotCard(shot: shot),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class FrameDetailHeader extends StatelessWidget {
  const FrameDetailHeader({required this.frame, super.key});

  final Frame frame;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_frames, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                frame.type,
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            frame.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          Text(frame.guide.isEmpty ? '촬영 가이드가 아직 없어요.' : frame.guide),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InfoChip(icon: Icons.repeat, label: frame.shootingCycle),
              InfoChip(
                icon: Icons.photo_library_outlined,
                label: '${frame.photoCount}회차',
              ),
              InfoChip(icon: Icons.group_outlined, label: '${frame.memberCount}명'),
            ],
          ),
        ],
      ),
    );
  }
}

class EmptyShotState extends StatelessWidget {
  const EmptyShotState({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              '아직 촬영 기록이 없어요',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              '오른쪽 아래 버튼으로 사진 URL과 메모를 남겨 첫 회차를 시작하세요.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ShotCard extends StatelessWidget {
  const ShotCard({required this.shot, super.key});

  final Shot shot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shot.photoUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                shot.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
                  color: Color(0xFFF3E5EA),
                  child: Center(child: Text('이미지를 불러올 수 없어요')),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        shot.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Text(_formatTimestamp(shot.shotAt)),
                  ],
                ),
                if (shot.memo.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(shot.memo),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTimestamp(Timestamp? timestamp) {
  if (timestamp == null) {
    return '방금 전';
  }

  final date = timestamp.toDate();
  return '${date.year}.${_twoDigits(date.month)}.${_twoDigits(date.day)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
