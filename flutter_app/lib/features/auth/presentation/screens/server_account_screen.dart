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
  bool _checkingName = false;
  String? _nameStatus;
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
                    // 흰 화면 위라 글라스 대신 단색 시트.
                    solid: true,
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
                    onChanged: (_) => setState(() => _nameStatus = null),
                    maxLength: 10,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: '사인 · 영문 소문자 2~10자',
                    ),
                  ),
                  TextButton(
                    onPressed: _checkingName
                        ? null
                        : () async {
                            final name = _masthead.text.trim();
                            if (!RegExp(r'^[a-z]{2,10}$').hasMatch(name)) {
                              setState(
                                () => _nameStatus = '영문 소문자 2~10자를 입력해 주세요.',
                              );
                              return;
                            }
                            setState(() {
                              _checkingName = true;
                              _nameStatus = null;
                            });
                            final available = await widget.auth
                                .isMastheadAvailable(name);
                            if (mounted) {
                              setState(() {
                                _checkingName = false;
                                if (_masthead.text.trim() != name) return;
                                _nameStatus = available == null
                                    ? '이름을 확인하지 못했어요. 다시 시도해 주세요.'
                                    : available
                                    ? '쓸 수 있는 사인이에요.'
                                    : '이미 있는 사인이에요.';
                              });
                            }
                          },
                    child: Text(_checkingName ? '확인 중…' : '사인 중복 확인'),
                  ),
                  if (_nameStatus != null) Text(_nameStatus!),
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
                    '오늘의 색과 스케치북·반응·색 기록을 서버에서 확인할 수 있어요. 새 표지 업로드는 준비 중이에요.',
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
