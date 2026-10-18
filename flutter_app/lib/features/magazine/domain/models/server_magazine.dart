import '../../../issue/domain/models/server_issue.dart';

class ServerMagazine {
  final String masthead;
  final int issueCount;
  final bool subscribed;
  final ServerIssue? today;
  final ServerPage<ServerIssue> page;
  const ServerMagazine({
    required this.masthead,
    required this.issueCount,
    required this.subscribed,
    required this.today,
    required this.page,
  });
}
