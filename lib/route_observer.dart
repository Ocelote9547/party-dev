import 'package:flutter/material.dart';

/// Observador global de rutas para reanudar la música del menú
/// al volver de un juego (ver MainShell.didPopNext).
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
