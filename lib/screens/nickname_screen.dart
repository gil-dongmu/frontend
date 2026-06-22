import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/common.dart';

/// 신규 회원 닉네임 설정 화면.
///
/// 백엔드 로그인 응답의 `isNewUser == true` 일 때 노출된다.
/// `PATCH /api/v1/users/me` 로 닉네임을 저장하며, 중복(409)이면 인라인 에러를 띄운다.
class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _submitting = false;

  // 백엔드 제약: @NotBlank @Size(max = 50)
  static const _maxLength = 50;

  bool get _valid {
    final v = _controller.text.trim();
    return v.isNotEmpty && v.length <= _maxLength;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_valid || _submitting) return;
    final app = context.read<AppState>();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await app.setNickname(_controller.text.trim());
      if (mounted) widget.onDone();
    } on ApiException catch (e) {
      setState(() {
        _error = e.isDuplicateNickname ? '이미 사용 중인 닉네임이에요.' : e.message;
      });
    } on NetworkException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Text('STEP 0', style: AppType.kicker(color: AppColors.vermilion)),
              const SizedBox(height: 12),
              Text('어떻게\n불러드릴까요?', style: AppType.display(size: 36, height: 1.18)),
              const SizedBox(height: 14),
              Text(
                '길동무에서 사용할 닉네임을 정해주세요.\n나중에 마이페이지에서 바꿀 수 있어요.',
                style: AppType.serif(size: 14, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLength: _maxLength,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                  setState(() {});
                },
                onSubmitted: (_) => _submit(),
                style: AppType.body(size: 16, weight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: '닉네임',
                  filled: true,
                  fillColor: AppColors.paper,
                  errorText: _error,
                  counterText: '',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.vermilion, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.vermilion),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.vermilion, width: 1.5),
                  ),
                ),
              ),
              const Spacer(flex: 3),
              Opacity(
                opacity: _valid && !_submitting ? 1 : 0.4,
                child: GdmButton(
                  _submitting ? '저장 중…' : '다음',
                  primary: true,
                  full: true,
                  icon: Icons.arrow_forward,
                  onTap: _valid && !_submitting ? _submit : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
