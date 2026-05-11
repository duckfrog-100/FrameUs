import 'package:flutter/material.dart';

import '../models/frame.dart';
import '../services/firestore_service.dart';
import '../widgets/error_state.dart';
import '../widgets/info_chip.dart';
import 'frame_create_screen.dart';
import 'frame_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('FrameUs'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FrameCreateScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('프레임 만들기'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Frame>>(
          stream: firestoreService.watchFrames(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ErrorState(
                title: '프레임을 불러오지 못했어요',
                message: '${snapshot.error}',
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final frames = snapshot.data ?? <Frame>[];

            if (frames.isEmpty) {
              return const EmptyFrameState();
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              itemCount: frames.length + 1,
              separatorBuilder: (_, index) =>
                  SizedBox(height: index == 0 ? 18 : 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const HeroPanel();
                }

                final frame = frames[index - 1];
                return FrameCard(
                  frame: frame,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FrameDetailScreen(frameId: frame.id),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}


class HeroPanel extends StatelessWidget {
  const HeroPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [colorScheme.primaryContainer, colorScheme.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.photo_camera_front, color: colorScheme.primary, size: 36),
          const SizedBox(height: 18),
          Text(
            '같은 구도로 쌓는\n우리만의 감성 기록',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            '프레임을 만들고 촬영 가이드를 공유한 뒤, 회차별 사진과 메모를 함께 남겨보세요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class EmptyFrameState extends StatelessWidget {
  const EmptyFrameState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_frames_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              '첫 프레임을 만들어보세요',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              '커플, 친구, 개인 기록을 위한 촬영 주기와 구도 가이드를 정할 수 있어요.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FrameCreateScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('프레임 만들기'),
            ),
          ],
        ),
      ),
    );
  }
}

class FrameCard extends StatelessWidget {
  const FrameCard({required this.frame, required this.onTap, super.key});

  final Frame frame;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      frame.type,
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                frame.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
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
                  InfoChip(
                    icon: Icons.group_outlined,
                    label: '${frame.memberCount}명',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
