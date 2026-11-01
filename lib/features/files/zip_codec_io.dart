import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> deflateRaw(Uint8List b) async =>
    Uint8List.fromList(ZLibCodec(raw: true, level: 6).encode(b));

Future<Uint8List> inflateRaw(Uint8List b) async =>
    Uint8List.fromList(ZLibCodec(raw: true).decode(b));
