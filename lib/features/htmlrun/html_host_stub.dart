import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'html_model.dart';

bool get hostSupported => false;
Future<List<HtmlApp>> hostList() async => [];
Future<HtmlApp?> hostAdd() async => null;
Future<void> hostDelete(String id) async {}
Widget hostView(HtmlApp app) => const SizedBox.shrink();
Future<HtmlApp?> hostAddBytes(String name, Uint8List bytes, {required bool zip}) async => null;
Future<Uint8List?> hostReadBytes(String id) async => null;
