// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:himotoku/Data/database/database.dart';
import 'package:himotoku/Data/models/Manga.dart';
import 'package:himotoku/Views/RouteBuilder.dart';
import 'package:isar/isar.dart';
import 'package:himotoku/Data/Constants.dart';
import 'package:himotoku/Data/models/Setting.dart';
import 'package:himotoku/Views/explore.dart';
import 'package:himotoku/Widgets/Library/ComfortableTile.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';

class Library extends StatefulWidget {
  const Library({Key? key}) : super(key: key);

  @override
  _LibraryState createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  StreamSubscription<void>? cancelSubscription;
  FilterOptions? filterOptions;
  List<Manga> mangaInLibrary = [];
  LibrarySort sortSettings = LibrarySort.az;
  bool isUpdating = false;

  @override
  void dispose() {
    cancelSubscription!.cancel();
    super.dispose();
  }

  @override
  void initState() {
    Stream<void> instanceChanged =
        isarDB.mangas.watchLazy(fireImmediately: true);
    cancelSubscription = instanceChanged.listen((event) {
      updateSettings();
    });

    super.initState();
    validatePermissions();
  }

  updateSettings() async {
    var settings = await isarDB.settings.get(0);
    setState(() {
      sortSettings =
          settings != null ? settings.sortSettings : DEFAULT_LIBRARY_SORT;
      filterOptions =
          settings != null ? settings.filterOptions : FilterOptions();
    });
    sortAndFilterLibrary();
  }

  sortAndFilterLibrary() async {
    var inLibrary = isarDB.mangas
        .where()
        .inLibraryEqualTo(true)
        .filter()
        .optional(
            filterOptions?.started == true,
            (query) =>
                query.chaptersElement((chapter) => chapter.isReadEqualTo(true)))
        // ! technically the same condition as above with "false" would
        // work but this might be faster and is clearer.
        .optional(filterOptions?.unread == true,
            (query) => query.unreadCountGreaterThan(0));

    QueryBuilder<Manga, Manga, QAfterSortBy>? sortQuery;
    List<Manga> library = [];

    switch (sortSettings) {
      case LibrarySort.az:
        sortQuery = inLibrary.sortByMangaName();
        break;
      case LibrarySort.za:
        sortQuery = inLibrary.sortByMangaNameDesc();
        break;
      case LibrarySort.status:
        sortQuery = inLibrary.sortByStatus();
        break;
      case LibrarySort.statusDesc:
        sortQuery = inLibrary.sortByStatusDesc();
        break;
      case LibrarySort.chapterCount:
        sortQuery = inLibrary.sortByChapterCount();
        break;
      case LibrarySort.chapterCountDesc:
        sortQuery = inLibrary.sortByChapterCountDesc();
        break;
      case LibrarySort.unreadCount:
        sortQuery = inLibrary.sortByUnreadCount();
        break;
      case LibrarySort.unreadCountDesc:
        sortQuery = inLibrary.sortByUnreadCountDesc();

        break;
      default:
        sortQuery = null;
        break;
      // case LibrarySort.unread:
      //   break;
    }

    library = await sortQuery?.findAll() ?? await inLibrary.findAll();
    setState(() {
      mangaInLibrary = library;
    });
  }

  ListView SortTab(StateSetter setModalState) {
    return ListView(
      children: [
        ListTile(
          leading: sortSettings == LibrarySort.az
              ? const Icon(Icons.arrow_upward)
              : (sortSettings == LibrarySort.za
                  ? const Icon(Icons.arrow_downward)
                  : null),
          title: const Text("Alphabetically"),
          onTap: () async {
            if (sortSettings == LibrarySort.az) {
              sortSettings = LibrarySort.za;
            } else {
              sortSettings = LibrarySort.az;
            }

            // Cause update in modal.
            setModalState(() {});

            // Update library.
            sortAndFilterLibrary();

            await isarDB.writeTxn(() async {
              var settings = await isarDB.settings.get(0);
              await isarDB.settings
                  .put(settings!.copyWith(newSortSettings: sortSettings));
            });
          },
        ),
        ListTile(
          leading: sortSettings == LibrarySort.status
              ? const Icon(Icons.arrow_upward)
              : (sortSettings == LibrarySort.statusDesc
                  ? const Icon(Icons.arrow_downward)
                  : null),
          onTap: () async {
            // Cause update in modal.
            setModalState(() {
              if (sortSettings == LibrarySort.status) {
                sortSettings = LibrarySort.statusDesc;
              } else {
                sortSettings = LibrarySort.status;
              }
            });
            // Update library.
            sortAndFilterLibrary();

            await isarDB.writeTxn(() async {
              var settings = await isarDB.settings.get(0);
              await isarDB.settings
                  .put(settings!.copyWith(newSortSettings: sortSettings));
            });
          },
          title: const Text("Status"),
        ),
        ListTile(
          leading: sortSettings == LibrarySort.chapterCount
              ? const Icon(Icons.arrow_upward)
              : (sortSettings == LibrarySort.chapterCountDesc
                  ? const Icon(Icons.arrow_downward)
                  : null),
          onTap: () async {
            // Cause update in modal.
            setModalState(() {
              if (sortSettings == LibrarySort.chapterCount) {
                sortSettings = LibrarySort.chapterCountDesc;
              } else {
                sortSettings = LibrarySort.chapterCount;
              }
            });
            // Update library.
            sortAndFilterLibrary();

            await isarDB.writeTxn(() async {
              var settings = await isarDB.settings.get(0);
              await isarDB.settings
                  .put(settings!.copyWith(newSortSettings: sortSettings));
            });
          },
          title: const Text("Chapter Count"),
        ),
        ListTile(
          leading: sortSettings == LibrarySort.unreadCount
              ? const Icon(Icons.arrow_upward)
              : (sortSettings == LibrarySort.unreadCountDesc
                  ? const Icon(Icons.arrow_downward)
                  : null),
          onTap: () async {
            // Cause update in modal.
            setModalState(() {
              if (sortSettings == LibrarySort.unreadCount) {
                sortSettings = LibrarySort.unreadCountDesc;
              } else {
                sortSettings = LibrarySort.unreadCount;
              }
            });
            // Update library.
            sortAndFilterLibrary();

            await isarDB.writeTxn(() async {
              var settings = await isarDB.settings.get(0);
              await isarDB.settings
                  .put(settings!.copyWith(newSortSettings: sortSettings));
            });
          },
          title: const Text("Unread Count"),
        ),
      ],
    );
  }

  ListView FilterTab(StateSetter setModalState) {
    return ListView(
      children: [
        CheckboxListTile(
          value: filterOptions?.started,
          onChanged: (value) async {
            setModalState(() {
              filterOptions?.started = value!;
            });
            sortAndFilterLibrary();
            await isarDB.writeTxn(() async {
              var settings = await isarDB.settings.get(0);
              await isarDB.settings.put(settings!.copyWith(
                  nFilterOptions:
                      settings.filterOptions.copyWith(newStarted: value)));
            });
          },
          title: const Text("Started"),
        ),
        CheckboxListTile(
          value: filterOptions?.unread,
          onChanged: (value) async {
            setModalState(() {
              filterOptions?.unread = value!;
            });
            sortAndFilterLibrary();
            await isarDB.writeTxn(() async {
              var settings = await isarDB.settings.get(0);
              await isarDB.settings.put(settings!.copyWith(
                  nFilterOptions:
                      settings.filterOptions.copyWith(newUnread: value)));
            });
          },
          title: const Text("Unread"),
        )
      ],
    );
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      title: const Text("Library"),
      actions: [
        // IconButton(onPressed: onTest, icon: Icon(Icons.abc)),
        IconButton(
            onPressed: issueUpdateWorker,
            icon: Icon(Icons.refresh_rounded),
            tooltip: "Update library"),
        IconButton(
          onPressed: () {
            showSearch(
                context: context, delegate: CustomSearchClass(filterOptions!));
          },
          icon: const Icon(Icons.search),
          tooltip: "Search in library",
        )
      ],
      automaticallyImplyLeading: false,
    );
  }

  FloatingActionButton filterFloatingButton(BuildContext context) {
    return FloatingActionButton(
        tooltip: "Sort and Filter",
        onPressed: () {
          showModalBottomSheet(
            backgroundColor: Theme.of(context).colorScheme.background,
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setModalState) => DefaultTabController(
                  length: 2,
                  child: Scaffold(
                    appBar: AppBar(
                      primary: false,
                      toolbarHeight: 0,
                      automaticallyImplyLeading: false,
                      bottom: TabBar(
                        labelColor: Theme.of(context).colorScheme.onBackground,
                        indicatorColor: Theme.of(context).colorScheme.primary,
                        tabs: [
                          Tab(
                            text: "Sort",
                          ),
                          Tab(
                            text: "Filter",
                          )
                        ],
                      ),
                    ),
                    body: TabBarView(children: [
                      SortTab(setModalState),
                      FilterTab(setModalState),
                    ]),
                  ),
                ),
              );
            },
          );
        },
        child: const Icon(Icons.filter_list_rounded));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: filterFloatingButton(context),
      appBar: appBar(context),
      body: mangaInLibrary.isNotEmpty
          ? GridView.builder(
              itemCount: mangaInLibrary.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                childAspectRatio: 2 / 3,
                crossAxisCount: 2,
              ),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ComfortableTile(
                    mangaInLibrary[index],
                    cacheImage: true,
                  ),
                );
              },
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("(ﾉಥ益ಥ）ﾉ ┻━┻",
                      style:
                          TextStyle(fontSize: 35, fontWeight: FontWeight.bold)),
                  const Text("You have nothing in your library."),
                  Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Navigate to "),
                          TextButton(
                              onPressed: () => Navigator.of(context)
                                  .push(createRoute(Explore())),
                              child: const Text(
                                "Explore",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )),
                          const Text("to add to your library.")
                        ],
                      )),
                ],
              ),
            ),
    );
  }

  void validatePermissions() async {
    if (!await Permission.manageExternalStorage.isGranted) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => FilePermissionDialog(ctx));
    }
  }

  FilePermissionDialog(BuildContext ctx) {
    return AlertDialog(
      shape: Border.all(),
      title: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 20),
          children: [
            TextSpan(text: "Allow "),
            TextSpan(
                text: "Himotoku",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: " to manage files on your device?"),
          ],
        ),
      ),
      content: Text(
          "Himotoku needs permission to manage files on your device for backup, downloading chapters etc."),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
          },
          child: Text("Deny"),
        ),
        TextButton(
          onPressed: () async {
            await Permission.manageExternalStorage.request();
            Navigator.of(ctx).pop();
          },
          child: Text("Allow"),
        )
      ],
    );
  }

  issueUpdateWorker() async {
    await Workmanager().registerOneOffTask("library_update", "library_update");
  }

  // void onTest() async {
  //   var updatedManga = mangaInLibrary[0];
  //   var updatedManga2 = mangaInLibrary[1];
  //   var updatedChap = List<Chapter>.from(updatedManga.chapters);
  //   var updatedChap2 = List<Chapter>.from(updatedManga2.chapters);
  //   updatedChap.removeAt(Random().nextInt(updatedChap.length));
  //   updatedChap2.removeAt(Random().nextInt(updatedChap2.length));
  //   updatedManga.chapters = updatedChap;
  //   updatedManga2.chapters = updatedChap2;

  //   await isarDB.writeTxn(() async {
  //     await isarDB.mangas.put(updatedManga);
  //     await isarDB.mangas.put(updatedManga2);
  //   });
  // }
}

class CustomSearchClass extends SearchDelegate {
  CustomSearchClass(this.filterCondition);

  FilterOptions filterCondition;
  var results = [];

  @override
  List<Widget> buildActions(BuildContext context) {
// this will show clear query button
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
// adding a back button to close the search
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return query.isNotEmpty
        ? GridView.builder(
            itemCount: results.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 4, mainAxisSpacing: 4),
            itemBuilder: (context, index) {
              return ComfortableTile(results[index]);
            },
          )
        : Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    getResults();
    return query.isNotEmpty
        ? GridView.builder(
            itemCount: results.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 4, mainAxisSpacing: 4),
            itemBuilder: (context, index) {
              return ComfortableTile(results[index]);
            },
          )
        : Container();
  }

  getResults() {
    if (query.isNotEmpty) {
      results.clear();
      results = isarDB.mangas
          .filter()
          .inLibraryEqualTo(true)
          .optional(filterCondition.started == true,
              (query) => query.chaptersElement((q) => q.isReadEqualTo(true)))
          .mangaNameContains(query, caseSensitive: false)
          .findAllSync();
    }
  }
}
