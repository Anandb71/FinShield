import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('Backend Connectivity Verification', () async {
    final stopwatch = Stopwatch()..start();
    final url = Uri.parse('http://127.0.0.1:8000/docs');

    print('\n🔄 Connecting to Finsight Backend...');
    print('   Target: $url');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      
      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;

      if (response.statusCode == 200) {
        print('\n✅ BACKEND ONLINE (Latency: $latency ms)');
        print('   Status: ${response.statusCode}');
      } else {
        print('\n⚠️ BACKEND RESPONDED (Latency: $latency ms)');
        print('   Status: ${response.statusCode}');
        fail('Backend status was ${response.statusCode}');
      }
    } catch (e) {
      print('\n❌ BACKEND OFFLINE');
      print('   Error: $e');
      print('   Action: Start uvicorn');
      print('   Command: uvicorn app.main:app --reload --port 8000');
      fail('Backend connection failed');
    }
  });
}
