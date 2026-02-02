import 'dart:async';
import 'package:flutter/material.dart';

class InfiniteMarquee extends StatefulWidget {
  final List<Widget> children;
  final bool reverse;
  final double speed; // Pixels per second

  const InfiniteMarquee({
    super.key,
    required this.children,
    this.reverse = false,
    this.speed = 30.0,
  });

  @override
  State<InfiniteMarquee> createState() => _InfiniteMarqueeState();
}

class _InfiniteMarqueeState extends State<InfiniteMarquee> {
  late ScrollController _scrollController;
  late Timer _timer;
  double _scrollPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: 0.0);

    // Démarrer l'animation après le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.reverse) {
        // Pour le reverse, on commence peut-être de la fin ?
        // Non, on va juste scroller dans l'autre sens ou inverser la liste ?
        // Le plus simple pour "reverse" est de scroller vers la gauche normalement,
        // mais si on veut l'effet "droite à gauche", c'est le standard.
        // "gauche à droite" (reverse) : on peut utiliser reverse: true dans ListView
        // et scroller "positivement" ce qui ira visuellement de gauche à droite.
        _startScrolling();
      } else {
        _startScrolling();
      }
    });
  }

  void _startScrolling() {
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_scrollController.hasClients) return;

      // Vitesse : pixels par frame (approx 60fps)
      // speed = 30 px/sec => 0.5 px/frame
      double delta = widget.speed / 60;

      _scrollPosition += delta;

      // Si on dépasse une certaine limite (ex: maxScrollExtent), on pourrait reset.
      // Mais avec ListView.builder infini, on continue juste.
      // Pour éviter l'overflow de double, on peut reset périodiquement si on connaît la taille du contenu.
      // Une astuce simple : ListView.builder infini.

      // Note: jumpTo est plus performant que animateTo pour un mouvement continu frame-par-frame
      _scrollController.jumpTo(_scrollPosition);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox();

    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      // Si reverse est true, la ListView commence à droite et défile vers la gauche (standard arabe/hébreu)
      // Mais pour une animation visuelle :
      // Normal : Items [1, 2, 3] -> Défile vers la gauche (on voit 2, 3...)
      // Reverse : Items [1, 2, 3] -> Défile vers la droite ?
      // ListView(reverse: true) inverse l'ordre visuel et le scroll.
      reverse: widget.reverse,
      physics:
          const NeverScrollableScrollPhysics(), // Désactiver le scroll manuel
      itemBuilder: (context, index) {
        // Modulo pour répéter les enfants indéfiniment
        final itemIndex = index % widget.children.length;
        return widget.children[itemIndex];
      },
    );
  }
}
