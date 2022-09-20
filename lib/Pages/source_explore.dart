import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:yomu/Data/Manga.dart';
import 'package:yomu/Extensions/extension.dart';
import 'package:yomu/Widgets/Library/ComfortableTile.dart';
import 'package:yomu/Widgets/Library/MangaGridView.dart';

class SourceExplore extends StatefulWidget {
  const SourceExplore(this.extension, {Key? key}) : super(key: key);

  final Extension extension;
  @override
  _SourceExploreState createState() => _SourceExploreState();
}

class _SourceExploreState extends State<SourceExplore> {
  // TODO: maybe allow extra loading using paramater of pagingcontroller
  final PagingController<int, Manga> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void didUpdateWidget(SourceExplore oldWidget) {
    if (oldWidget.extension != widget.extension) {
      _pagingController.refresh();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: CustomSearchClass(),
                );
              },
              icon: const Icon(Icons.search))
        ],
        title: Text(
          widget.extension.name,
        ),
      ),
      // TODO: customize refreshindicator
      body: MangaGridView(widget.extension, _pagingController),
    );
  }
}

class CustomSearchClass extends SearchDelegate {
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

  getResults() {
    if (query.isNotEmpty) {
      results.clear();
      // results = isarInstance!.mangas
      //     .filter()
      //     .inLibraryEqualTo(true)
      //     .mangaNameContains(query, caseSensitive: false)
      //     .findAllSync();
      print("got called: $query");
      print(results);
    }
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
}
