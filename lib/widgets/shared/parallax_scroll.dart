import 'package:flutter/material.dart';

class ParallaxScroll extends StatelessWidget {
  final Widget header;
  final List<Widget> children;

  const ParallaxScroll({super.key, required this.header, this.children = const []});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 250,
          flexibleSpace: FlexibleSpaceBar(background: header),
          pinned: true,
        ),
        SliverList(
          delegate: SliverChildListDelegate(children),
        ),
      ],
    );
  }
}
