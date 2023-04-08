import 'package:ip_monitor/ip_monitor.dart' as ip_monitor;

void main(List<String> arguments) {
  print('IP Monitor Started - ${DateTime.now().toIso8601String()}');
  ip_monitor.main();
}
