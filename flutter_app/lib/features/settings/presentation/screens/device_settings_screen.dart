import 'package:flutter/material.dart';
import '../../../drafts/data/local_library.dart';

class DeviceSettingsScreen extends StatelessWidget {
  final LocalLibrary library;
  const DeviceSettingsScreen({super.key, required this.library});
  Future<void> _save(BuildContext context, Future<void> action) async {
    try {
      await action;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정을 저장하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: library,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('기기 설정')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('이 설정은 앱을 다시 켜도 이 기기에 유지돼요.'),
          ),
          SwitchListTile(
            title: const Text('움직임 줄이기'),
            value: library.reduceMotion,
            onChanged: (v) => _save(context, library.settings(motion: v)),
          ),
          SwitchListTile(
            title: const Text('투명도 줄이기'),
            subtitle: const Text('메뉴 배경을 단색으로 표시해요.'),
            value: library.reduceTransparency,
            onChanged: (v) => _save(context, library.settings(transparency: v)),
          ),
          SwitchListTile(
            title: const Text('큰 글씨'),
            value: library.largeText,
            onChanged: (v) => _save(context, library.settings(text: v)),
          ),
          ListTile(
            title: const Text('초안 보관 안내'),
            trailing: const Icon(Icons.info_outline),
            onTap: () => showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('이 기기에 보관돼요'),
                content: const Text(
                  '초안과 편집한 사진은 앱 전용 공간에 저장돼요. 앱 삭제나 기기 초기화 전에 표지 이미지 내보내기로 필요한 사진을 보관해 주세요. 서버 올리기과 동기화는 별도 기능이에요.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('확인'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
