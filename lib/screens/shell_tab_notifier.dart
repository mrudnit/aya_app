import 'package:flutter/material.dart';
enum ShellTab { home, log, analytics }
final shellTabNotifier = ValueNotifier<ShellTab>(ShellTab.home);
