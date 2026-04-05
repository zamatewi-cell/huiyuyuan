import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse('http://127.0.0.1:8000/api/products?page=1&page_size=500'));
  final response = await request.close();
  final body = await utf8.decodeStream(response);
  final items = jsonDecode(body) as List<dynamic>;
  for (final raw in items.cast<Map<String, dynamic>>()) {
    final name = (raw['name'] ?? '').toString();
    if (name.contains('108') || name.contains('∑') || name.contains('÷È') || name.contains(' ÷¥Æ') || name.contains(' ÷¡¥')) {
      stdout.writeln('${raw['id']}\t$name\t${raw['material']}\t${raw['category']}');
    }
  }
}
