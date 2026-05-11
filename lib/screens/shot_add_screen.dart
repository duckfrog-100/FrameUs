import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class ShotAddScreen extends StatefulWidget {
  const ShotAddScreen({required this.frameId, super.key});

  final String frameId;

  @override
  State<ShotAddScreen> createState() => _ShotAddScreenState();
}

class _ShotAddScreenState extends State<ShotAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _titleController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final _memoController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _photoUrlController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _saveShot() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _firestoreService.addShot(
        frameId: widget.frameId,
        title: _titleController.text.trim(),
        photoUrl: _photoUrlController.text.trim(),
        memo: _memoController.text.trim(),
      );

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('촬영 기록이 추가되었습니다.')),
        );
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장에 실패했습니다: ${error.message ?? error.code}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '촬영 기록 추가',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '회차 제목',
                  hintText: '예: 1주차 기록',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '회차 제목을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _photoUrlController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '사진 URL',
                  hintText: 'https://example.com/photo.jpg',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return null;
                  }
                  final uri = Uri.tryParse(text);
                  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
                    return '올바른 URL을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _memoController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: '메모',
                  hintText: '오늘의 감정, 포즈 팁, 다음 촬영 아이디어를 적어보세요.',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _saveShot,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('기록 저장'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
