import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// 图标转换缓存
final Map<String, IconData> _petEmojiCache = {};
final Map<String, IconData> _moodEmojiCache = {};
final Map<String, IconData> _anyEmojiCache = {};

// 宠物emoji到图标映射
const Map<String, IconData> _petEmojiMap = {
  '🥚': Icons.egg_outlined,
  '🦊': CupertinoIcons.hare,
  '🐺': CupertinoIcons.flame,
  '🐰': CupertinoIcons.hare,
  '🦌': CupertinoIcons.leaf_arrow_circlepath,
  '🦔': CupertinoIcons.leaf_arrow_circlepath,
  '🐦': CupertinoIcons.paperplane,
  '🐿️': CupertinoIcons.bolt,
  '🦝': CupertinoIcons.eye,
  '🐻': CupertinoIcons.house,
  '🐧': CupertinoIcons.snow,
  '🦉': CupertinoIcons.moon,
  '🐨': CupertinoIcons.cloud,
  '🐼': CupertinoIcons.circle_grid_hex,
  '🦋': CupertinoIcons.sparkles,
  '🖤': CupertinoIcons.moon_fill,
  '🐾': CupertinoIcons.paw,
};

// 心情emoji到图标映射
const Map<String, IconData> _moodEmojiMap = {
  '😄': CupertinoIcons.hand_thumbsup_fill,
  '🙂': CupertinoIcons.hand_thumbsup,
  '😌': CupertinoIcons.heart,
  '😢': CupertinoIcons.drop,
  '😭': CupertinoIcons.cloud_rain,
};

// 通用emoji到图标映射
const Map<String, IconData> _anyEmojiMap = {
  // 记忆亮点
  '🎯': CupertinoIcons.scope,
  '🔥': CupertinoIcons.flame,
  '⚡': CupertinoIcons.bolt_fill,
  '💬': CupertinoIcons.chat_bubble_2,
  '🏆': CupertinoIcons.rosette,
  '⬆️': CupertinoIcons.arrow_up_circle_fill,
  // 心情
  '😄': CupertinoIcons.hand_thumbsup_fill,
  '🙂': CupertinoIcons.hand_thumbsup,
  '😌': CupertinoIcons.heart,
  '😢': CupertinoIcons.drop,
  '😭': CupertinoIcons.cloud_rain,
  '😐': CupertinoIcons.smiley,
  '😟': CupertinoIcons.smiley_filled,
  // 道具/零食
  '🍪': CupertinoIcons.gift,
  '🏠': CupertinoIcons.house_fill,
  '👗': CupertinoIcons.checkmark_seal,
  '🛒': CupertinoIcons.cart,
  '🪙': CupertinoIcons.bitcoin_circle,
  // 商店物品
  '🌸': CupertinoIcons.flower,
  '🌊': CupertinoIcons.waveform,
  '🍂': CupertinoIcons.flame,
  '❄️': CupertinoIcons.snow,
  '🌃': CupertinoIcons.moon,
  '🎩': CupertinoIcons.house,
  '🕶️': CupertinoIcons.eye,
  '🧣': CupertinoIcons.movieclapper,
  '🛡️': CupertinoIcons.shield,
  '✨': CupertinoIcons.sparkles,
  '🐟': CupertinoIcons.circle_filled,
  '⭐': CupertinoIcons.star_fill,
  '🔮': CupertinoIcons.circle_filled,
  '🛋️': CupertinoIcons.house,
  '🌱': CupertinoIcons.leaf,
  '🖼️': CupertinoIcons.photo,
  '🏮': CupertinoIcons.lightbulb,
  '🧶': CupertinoIcons.circle_filled,
  '💫': CupertinoIcons.sparkles,
  '🪟': CupertinoIcons.house,
  '🔒': CupertinoIcons.lock_fill,
};

/// 宠物emoji到图标转换（带缓存）
IconData petEmojiToIcon(String emoji) {
  if (_petEmojiCache.containsKey(emoji)) {
    return _petEmojiCache[emoji]!;
  }
  final result = _petEmojiMap[emoji] ?? CupertinoIcons.hare;
  _petEmojiCache[emoji] = result;
  return result;
}

/// 心情emoji到图标转换（带缓存）
IconData moodEmojiToIcon(String emoji) {
  if (_moodEmojiCache.containsKey(emoji)) {
    return _moodEmojiCache[emoji]!;
  }
  final result = _moodEmojiMap[emoji] ?? CupertinoIcons.smiley;
  _moodEmojiCache[emoji] = result;
  return result;
}

/// 通用emoji到图标转换（带缓存）
IconData anyEmojiToIcon(String emoji) {
  if (_anyEmojiCache.containsKey(emoji)) {
    return _anyEmojiCache[emoji]!;
  }
  final result = _anyEmojiMap[emoji] ?? CupertinoIcons.circle;
  _anyEmojiCache[emoji] = result;
  return result;
}
