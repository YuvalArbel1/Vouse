// lib/presentation/providers/post/post_location_provider.dart

import 'package:riverpod/riverpod.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_location_entity.dart';

/// A [StateProvider] that holds the location chosen for a post.
///
/// If `null`, it means the user has not selected a location yet.
/// If non-null, it contains a [PlaceLocationEntity] with lat/long/address.
final postLocationProvider = StateProvider<PlaceLocationEntity?>((ref) => null);
