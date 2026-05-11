import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'frame_detail_screen.dart';

class FrameCreateScreen extends StatefulWidget {
  const FrameCreateScreen({super.key});

  @override
  State<FrameCreateScreen> createState() => _FrameCreateScreenState();
}

class _FrameCreateScreenState extends State<FrameCreateScreen> {
  static const List<String> _frameTypes = ['커플', '친구', '개인'];
  static const List<String> _shootingCycles = ['매일', '매주', '매월', '직접 설정'];

  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _frameNameController = TextEditingController();
  final _customCycleController = TextEditingController();
  final _guideController = TextEditingController();

  String _selectedFrameType = _frameTypes.first;
  String _selectedShootingCycle = _shootingCycles[1];
  bool _isSaving = false;

  @override
  void dispose() {
    _frameNameController.dispose();
    _customCycleController.dispose();
    _guideController.dispose();
    super.dispose();
  }

  Future<void> _saveFrame() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final shootingCycle = _selectedShootingCycle == '직접 설정'
        ? _customCycleController.text.trim()
        : _selectedShootingCycle;

    try {
      final frameId = await _firestoreService.createFrame(
        name: _frameNameController.text.trim(),
        type: _selectedFrameType,
        shootingCycle: shootingCycle,
        guide: _guideController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프레임이 생성되었습니다.')),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FrameDetailScreen(frameId: frameId),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장에 실패했습니다: ${error.message ?? error.code}')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장에 실패했습니다: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 프레임 만들기'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '기록할 관계와 구도를 정해주세요',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'MVP에서는 프레임 생성, 촬영 가이드, 회차별 사진 URL과 메모 저장을 지원합니다.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _frameNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '프레임명',
                    hintText: '예: 100일 커플 거울샷',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '프레임명을 입력해주세요.';
                    }
                    if (value.trim().length < 2) {
                      return '프레임명은 2자 이상 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedFrameType,
                  decoration: const InputDecoration(labelText: '프레임 유형'),
                  items: _frameTypes
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _selectedFrameType = value);
                          }
                        },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedShootingCycle,
                  decoration: const InputDecoration(labelText: '촬영 주기'),
                  items: _shootingCycles
                      .map(
                        (cycle) => DropdownMenuItem(
                          value: cycle,
                          child: Text(cycle),
                        ),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _selectedShootingCycle = value);
                          }
                        },
                ),
                if (_selectedShootingCycle == '직접 설정') ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _customCycleController,
                    decoration: const InputDecoration(
                      labelText: '직접 설정 주기',
                      hintText: '예: 매월 첫째 주 토요일',
                    ),
                    validator: (value) {
                      if (_selectedShootingCycle != '직접 설정') {
                        return null;
                      }
                      if (value == null || value.trim().isEmpty) {
                        return '직접 설정할 촬영 주기를 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 20),
                TextFormField(
                  controller: _guideController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: '촬영 가이드',
                    hintText: '예: 같은 벽 앞에서 상반신이 보이게 촬영하기',
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isSaving ? null : _saveFrame,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _isSaving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('프레임 생성'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
