// ignore_for_file:

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:himotoku/Data/database/database.dart';
import 'package:himotoku/Data/models/Setting.dart';

import '../../Widgets/Settings/SectionHeader.dart';

class ReaderSettings extends StatefulWidget {
  const ReaderSettings({Key? key}) : super(key: key);

  @override
  _ReaderSettingsState createState() => _ReaderSettingsState();
}

class _ReaderSettingsState extends State<ReaderSettings> {
  StreamSubscription<void>? cancelSubscription;
  bool? fullscreen;
  bool? splitTallImages;

  @override
  void dispose() {
    cancelSubscription!.cancel();
    super.dispose();
  }

  @override
  void initState() {
    try {
      Stream<void> settingsChanged =
          isarDB.settings.watchObjectLazy(0, fireImmediately: true);
      cancelSubscription = settingsChanged.listen((event) async {
        updateSettings();
      });
    } catch (e) {}
    super.initState();
  }

  updateSettings() async {
    var settings = await isarDB.settings.get(0);
    setState(() {
      splitTallImages = settings!.splitTallImages;
      fullscreen = settings.fullscreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reader")),
      body: ListView(children: [
        SectionHeader("View"),
        ListTile(
            title: const Text("Fullscreen",
                style: TextStyle(fontWeight: FontWeight.bold)),
            leading: Icon(
              Icons.fullscreen,
              color: Theme.of(context).colorScheme.primary,
            ),
            subtitle: const Text("Go fullscreen mode while reading."),
            trailing: Switch(
                thumbIcon: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Icon(Icons.check_rounded);
                  }
                  if (!states.contains(MaterialState.selected)) {
                    return Icon(Icons.close);
                  }
                  return null;
                }),
                value: fullscreen ?? false,
                onChanged: (value) async {
                  await isarDB.writeTxn(() async {
                    var settings = await isarDB.settings.get(0);
                    await isarDB.settings
                        .put(settings!.copyWith(newFullscreen: value));
                  });
                })),
        ListTile(
            title: const Text("Split tall images",
                style: TextStyle(fontWeight: FontWeight.bold)),
            leading: Icon(
              Icons.horizontal_split,
              color: Theme.of(context).colorScheme.primary,
            ),
            subtitle: const Text("Better image quality, but slighty slower."),
            trailing: Switch(
                thumbIcon: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Icon(Icons.check_rounded);
                  }
                  if (!states.contains(MaterialState.selected)) {
                    return Icon(Icons.close);
                  }
                  return null;
                }),
                value: splitTallImages ?? false,
                onChanged: (value) async {
                  await isarDB.writeTxn(() async {
                    var settings = await isarDB.settings.get(0);
                    await isarDB.settings
                        .put(settings!.copyWith(newSplitTallImages: value));
                  });
                }))
      ]),
    );
  }
}
