import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse('http://127.0.0.1:8000/api/products/HYY-HT005'));
  final response = await request.close();
  final body = await utf8.decodeStream(response);
  print(body);
}
