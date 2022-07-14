import 'dart:convert';

import 'dart:io';

class Reader {
  final RandomAccessFile file;

  Reader._init(this.file);

  static Future<Reader> create(File _file, {int index = 0}) async {
    var access = await _file.open();
    await access.setPosition(index);
    return Reader._init(access);
  }

  static Future<Reader> fromPath(String path) async =>
      Reader.create(File(path));

  Future<int> get take async {
    return file.readByte();
  }

  Future<String> nextChar() async {
    var next = await take;
    if (next & 128 == 0) {
      return utf8.decoder.convert([next]);
    } else if (next & 32 == 0) {
      return utf8.decoder.convert(await _takeSeveral(1, next));
    } else if (next & 16 == 0) {
      return utf8.decoder.convert(await _takeSeveral(2, next));
    } else {
      return utf8.decoder.convert(await _takeSeveral(3, next));
    }
  }

  Future<String> nextString(int count) async {
    var buffer = List<int>.empty(growable: true);

    for (var i = 0; i < count; i++) {
      var next = await take;
      buffer.add(next);
      if (next & 128 == 0) {
      } else if (next & 32 == 0) {
        buffer.add(await take);
      } else if (next & 16 == 0) {
        buffer.add(await take);
        buffer.add(await take);
      } else {
        buffer.add(await take);
        buffer.add(await take);
        buffer.add(await take);
      }
    }

    return utf8.decoder.convert(buffer);
  }

  Future<List<int>> _takeSeveral(int count, int starting) async =>
      [starting, for (int i = 0; i < count; i++) await take];

  Future<int> nextVariableInt() async {
    var v = 0;
    var shift = 0;
    var next = await take;
    while (next & 128 == 0) {
      v |= next << shift;
      next = await take;
      shift += 7;
    }
    v |= (next & 127) << shift;
    return v;
  }

  Future<int> nextInt64() async =>
      (await take << 56) |
      (await take << 48) |
      (await take << 40) |
      (await take << 32) |
      (await take << 24) |
      (await take << 16) |
      (await take << 8) |
      await take;

  Future<int> nextU8() async => (await take);

  Future<void> moveTo(int index) async {
    if (index < 0) throw Exception("Index is negative: $index");
    await file.setPosition(index);
  }

  Future<void> close() async {
    await file.close();
  }
}
