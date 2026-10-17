import '../../../../core/design/tokens.g.dart';
import '../../../../core/time/service_date.dart';

class ServerToday {
  final ServiceDate date;
  final List<EselPaint> candidates;
  final EselPaint? selected;
  final bool published;
  const ServerToday({
    required this.date,
    required this.candidates,
    required this.selected,
    required this.published,
  });
}
