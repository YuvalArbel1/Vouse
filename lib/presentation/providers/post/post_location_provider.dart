// lib/presentation/providers/post/post_location_provider.dart

import 'package:riverpod/riverpod.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_location_entity.dart';

/// Holds the location chosen for the post, or null if none is chosen.
final postLocationProvider = StateProvider<PlaceLocationEntity?>((ref) => null);
