import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ブラウザタブ内の現在ページに「一番上までスクロール」を要求する signal。
/// ボトムナビの「ブラウザ」タブをアクティブ時に再タップしたときに ++ する。
/// リスナー (BrowserHomePage / SearchResultPage) 側で ref.listen して発火。
final browserScrollToTopProvider = StateProvider<int>((ref) => 0);
