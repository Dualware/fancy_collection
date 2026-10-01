part of 'fancy_collection_core.dart';

/// A list position in an event path; a `null` index is a bulk change.
final class _Position {
  final int? index;

  const _Position(this.index);

  static const bulk = _Position(null);
}

sealed class _Pattern {
  const _Pattern();
}

/// `*`: matches everything from this segment on.
final class _Wildcard extends _Pattern {
  const _Wildcard();
}

/// `[*]`: matches any list position.
final class _AnyIndex extends _Pattern {
  const _AnyIndex();
}

final class _Index extends _Pattern {
  final int index;

  const _Index(this.index);
}

final class _Key extends _Pattern {
  final String key;

  const _Key(this.key);
}

String _formatPath(List<Object?> segments) {
  final buffer = StringBuffer();
  for (final segment in segments) {
    if (segment is _Position) {
      buffer.write('[${segment.index ?? '*'}]');
    } else {
      if (buffer.isNotEmpty) buffer.write('.');
      buffer.write(_escapeKey('$segment'));
    }
  }
  return buffer.toString();
}

String _escapeKey(String key) {
  if (key == '*') return r'\*';
  return key.replaceAllMapped(RegExp(r'[\\.\[\]]'), (m) => '\\${m[0]}');
}

List<_Pattern> _parsePath(String path) {
  Never fail(String message) =>
      throw ArgumentError.value(path, 'attributePath', message);

  final patterns = <_Pattern>[];
  final key = StringBuffer();
  var hasKey = false;
  var keyHadEscape = false;
  var afterIndex = false;
  var afterDot = false;

  void endKey() {
    if (!hasKey) return;
    final text = key.toString();
    patterns.add(text == '*' && !keyHadEscape ? const _Wildcard() : _Key(text));
    key.clear();
    hasKey = false;
    keyHadEscape = false;
  }

  var i = 0;
  while (i < path.length) {
    final char = path[i];
    if (afterIndex && char != '.' && char != '[') {
      fail('Expected "." or "[" after "]"');
    }
    switch (char) {
      case r'\':
        if (i + 1 == path.length) fail('Dangling escape character');
        key.write(path[i + 1]);
        hasKey = true;
        keyHadEscape = true;
        afterDot = false;
        i += 2;
      case '.':
        if (!hasKey && !afterIndex) fail('Empty key');
        endKey();
        afterIndex = false;
        afterDot = true;
        i++;
      case '[':
        if (afterDot) fail('Empty key');
        endKey();
        final close = path.indexOf(']', i);
        if (close < 0) fail('Unclosed "["');
        final content = path.substring(i + 1, close);
        final index = int.tryParse(content);
        if (content == '*') {
          patterns.add(const _AnyIndex());
        } else if (index != null && index >= 0) {
          patterns.add(_Index(index));
        } else {
          fail('Invalid list index "$content"');
        }
        afterIndex = true;
        afterDot = false;
        i = close + 1;
      case ']':
        fail('Unexpected "]"');
      default:
        key.write(char);
        hasKey = true;
        afterDot = false;
        i++;
    }
  }
  if (afterDot) fail('Empty key');
  endKey();
  return patterns;
}

/// Whether an event at [segments] is relevant to a listener on [patterns]:
/// both agree on every segment until one of them ends.
bool _matches(List<_Pattern> patterns, List<Object?> segments) {
  final common = min(patterns.length, segments.length);
  for (var i = 0; i < common; i++) {
    final segment = segments[i];
    switch (patterns[i]) {
      case _Wildcard():
        return true;
      case _AnyIndex():
        if (segment is! _Position) return false;
      case _Index(:final index):
        if (segment is! _Position) return false;
        if (segment.index == null) return true;
        if (segment.index != index) return false;
      case _Key(:final key):
        if (segment is _Position || '$segment' != key) return false;
    }
  }
  return true;
}
