import 'package:flutter_riverpod/flutter_riverpod.dart';

// 0 = Web / 1 = アプリ内。初期値はアプリ内。
final searchTabIndexProvider = StateProvider<int>((ref) => 1);
