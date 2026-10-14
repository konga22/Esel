import 'package:flutter/material.dart';
import '../../../../core/design/tokens.g.dart';
import '../../../../core/design/typography.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/http_client.dart';
import '../../../../core/ui/esel_button.dart';
import '../controllers/auth_controller.dart';
import 'login_sheet.dart';

/// Real API entry point while the remaining feature repositories are integrated.
/// Never render the legacy demo controllers as real server content.
class ServerAccountScreen extends StatefulWidget {
  final AuthController auth;
  final AppHttpClient http;
  const ServerAccountScreen({
    super.key,
    required this.auth,
    required this.http,
  });
  @override
  State<ServerAccountScreen> createState() => _ServerAccountScreenState();
}

class _ServerAccountScreenState extends State<ServerAccountScreen> {
  final _masthead = TextEditingController();
  bool _checking = true;
  String? _connectionError;
  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  @override
  void dispose() {
    _masthead.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _checking = true;
      _connectionError = null;
    });
    try {
      await widget.http.get('/health');
    } on Failure catch (error) {
      if (mounted) setState(() => _connectionError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _connectionError = '서비스에 연결하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: EselTokens.paper,
    body: SafeArea(
      child: AnimatedBuilder(
        animation: widget.auth,
        builder: (context, _) {
          final session = widget.auth.currentSession;
          return ListView(
            padding: const EdgeInsets.all(28),
            children: [
              const SizedBox(height: 40),
              Text('Esel', style: EselTypography.headlineLarge),
              const SizedBox(height: 12),
              Text(
                '평범한 하루의 착장이 한 권의 잡지가 되는 곳.',
                style: EselTypography.bodyMedium,
              ),
              const SizedBox(height: 48),
              if (_checking)
                const Center(child: CircularProgressIndicator())
              else if (_connectionError != null) ...[
                Text(_connectionError!, style: EselTypography.bodyMedium),
                const SizedBox(height: 20),
                EselButton(
                  label: '다시 연결하기',
                  isPrimary: true,
                  onTap: _checkConnection,
                ),
              ],
              const SizedBox(height: 20),
              if (session == null) ...[
                EselButton(
                  label: '로그인 · 회원가입',
                  isPrimary: true,
                  onTap: () => LoginSheet.show(
                    context,
                    authController: widget.auth,
                    onLoginSuccess: () {},
                  ),
                ),
              ] else ...[
                Text(
                  session.masthead.isEmpty
                      ? '내 잡지의 이름을 정해 주세요.'
                      : session.masthead,
                  style: EselTypography.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(session.email, style: EselTypography.bodyMedium),
                const SizedBox(height: 24),
                if (session.masthead.isEmpty) ...[
                  TextField(
                    controller: _masthead,
                    maxLength: 10,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: '제호 · 영문 소문자 2~10자',
                    ),
                  ),
                  const SizedBox(height: 16),
                  EselButton(
                    label: widget.auth.isLoading ? '저장 중…' : '제호 저장하기',
                    isPrimary: true,
                    onTap: () {
                      if (!widget.auth.isLoading) {
                        widget.auth.createProfile(_masthead.text.trim());
                      }
                    },
                  ),
                ] else ...[
                  Text(
                    '발행한 호 ${session.issueCount}권',
                    style: EselTypography.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '표지 발행과 잡지 둘러보기는 현재 연결 작업 중입니다.',
                    style: EselTypography.bodySmall,
                  ),
                ],
                const SizedBox(height: 24),
                EselButton(
                  label: '로그아웃',
                  isPrimary: false,
                  onTap: () {
                    if (!widget.auth.isLoading) widget.auth.logout();
                  },
                ),
              ],
              if (widget.auth.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  widget.auth.errorMessage!,
                  style: EselTypography.bodySmall.copyWith(
                    color: EselTokens.semanticRed,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    ),
  );
}
