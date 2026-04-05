library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/contact_service.dart';

typedef RecentContactsLoader = Future<List<ContactRecord>> Function({
  int limit,
});

final recentContactsLoaderProvider = Provider<RecentContactsLoader>((ref) {
  final service = ContactService();
  return ({int limit = 5}) => service.getRecentContacts(limit: limit);
});
