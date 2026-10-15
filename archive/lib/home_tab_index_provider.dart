import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeTabIndexProvider = StateProvider<int>((ref) => 0);

/// ホーム画面を開いた回数。
///
/// ホームのランダム表示系ウィジェットは、これを乱数の種に混ぜることで
/// 「ホームを開くたびに引き直す」挙動にする。build のたびに引くと
/// 再描画ごとに内容が入れ替わってちらつくため、契機を明示的に持たせる。
final homeVisitCounterProvider = StateProvider<int>((ref) => 0);
