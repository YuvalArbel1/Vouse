import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemChrome
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nb_utils/nb_utils.dart'; // For toast, etc.

import '../../../core/util/colors.dart'; // Where vPrimaryColor is defined
import '../../../core/resources/data_state.dart';
import '../../../domain/entities/google_maps/place_details_entity.dart';
import '../../../domain/entities/google_maps/place_location_entity.dart';
import '../../../domain/entities/google_maps/place_suggestion_entity.dart';
import '../../../domain/usecases/google_maps/reverse_geocode_usecase.dart';
import '../../../domain/usecases/google_maps/search_places_usecase.dart';
import '../../providers/google_maps/location_providers.dart';
import '../../providers/post/post_location_provider.dart';

/// A screen that allows the user to pick a location on a Google Map:
/// - Requests user permission for location, placing a red marker at the current position.
/// - Lets the user tap or drag the marker to adjust the position.
/// - Includes a search bar powered by the Google Places Autocomplete API to jump to addresses.
/// - Hides phone's nav bar (immersive mode) for a full-screen map experience.
/// - Two FloatingActionButtons:
///   - Left "Cancel" (X): closes without returning a location.
///   - Right "Confirm" (check): returns the chosen [LatLng] to the caller.
class SelectLocationScreen extends ConsumerStatefulWidget {
  const SelectLocationScreen({super.key});

  @override
  ConsumerState<SelectLocationScreen> createState() =>
      _SelectLocationScreenState();
}

class _SelectLocationScreenState extends ConsumerState<SelectLocationScreen> {
  /// Controller for the GoogleMap widget.
  GoogleMapController? _mapController;

  /// The currently picked location, stored as a LatLng for the final result.
  LatLng? _pickedLatLng;

  /// Google Maps Marker placed on the map, initialized once the user location is known.
  Marker? _marker;

  /// TextField controller for the search bar input.
  final TextEditingController _searchController = TextEditingController();

  /// Debounce timer used to delay autocomplete calls until the user stops typing.
  Timer? _debounce;

  /// List of autocomplete suggestions returned by the Places API.
  List<PlaceSuggestionEntity> _suggestions = [];

  @override
  void initState() {
    super.initState();
    // Enable immersive mode: hides both system status and nav bars.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Use a post-frame callback to request location once the widget has built.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  @override
  void dispose() {
    // Restore system UI to normal when leaving this screen.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Cancel the debounce timer if it's still active.
    _debounce?.cancel();

    // Dispose the search controller.
    _searchController.dispose();
    super.dispose();
  }

  /// Requests the user's location from [getCurrentLocationUseCaseProvider].
  /// If granted and successful, places a red marker and animates the map camera.
  Future<void> _initLocation() async {
    final getLocUseCase = ref.read(getCurrentLocationUseCaseProvider);

    // Call the domain layer to request current location (plus permission).
    final result = await getLocUseCase();

    // Check if we're still mounted before making setState calls.
    if (!mounted) return;

    // If success, place the marker and center camera.
    if (result is DataSuccess<PlaceLocationEntity>) {
      final loc = result.data!;
      setState(() {
        _pickedLatLng = LatLng(loc.latitude, loc.longitude);
        _marker = Marker(
          markerId: const MarkerId('my-marker'),
          position: _pickedLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          draggable: true,
          onDragEnd: (pos) => _pickedLatLng = pos, // update local on drag
        );
      });
      _moveCamera(_pickedLatLng!, 16);
    }
    // If failure, show a toast with the error.
    else if (result is DataFailed<PlaceLocationEntity>) {
      toast("Failed to get location: ${result.error?.error}");
    }
  }

  /// Animates the map camera to the given [latLng] and [zoom] level.
  void _moveCamera(LatLng latLng, double zoom) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, zoom),
      );
    }
  }

  /// Called once the map is created. We store the [controller], and
  /// if we already have a picked location, move the camera there.
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_pickedLatLng != null) {
      _moveCamera(_pickedLatLng!, 16);
    }
  }

  /// Called when the user taps somewhere on the map, updating
  /// [_pickedLatLng] and re-placing the marker there.
  void _onMapTap(LatLng latLng) {
    setState(() {
      _pickedLatLng = latLng;
      _marker = Marker(
        markerId: const MarkerId('my-marker'),
        position: latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        draggable: true,
        onDragEnd: (pos) => _pickedLatLng = pos,
      );
    });
  }

  /// Called when the user presses the checkmark FAB.
  /// If no location is chosen, we show a toast. Otherwise:
  /// - Optionally reverse geocode the lat/lng to get an address.
  /// - Build a [PlaceLocationEntity].
  /// - Store it in [postLocationProvider].
  /// - Pop this screen without returning a LatLng (the data is in the provider).
  Future<void> _onConfirm() async {
    if (_pickedLatLng == null) {
      toast("No location selected!");
      return;
    }

    // Grab lat/lng
    final lat = _pickedLatLng!.latitude;
    final lng = _pickedLatLng!.longitude;

    // Possibly do a reverse geocode
    final reverseUC = ref.read(reverseGeocodeUseCaseProvider);
    final reverseResult =
        await reverseUC.call(params: ReverseGeocodeParams(lat, lng));

    String? address;
    if (reverseResult is DataSuccess<String>) {
      address = reverseResult.data;
    }

    // Build the final location entity
    // If you have a place name from search, you can set it here too
    // For now, we'll rely on address alone
    final locationEntity = PlaceLocationEntity(
      latitude: lat,
      longitude: lng,
      address: address,
      name: null, // or some custom name
    );

    // Save to the postLocationProvider so the rest of the app sees it
    ref.read(postLocationProvider.notifier).state = locationEntity;

    // Finally pop
    Navigator.pop(context);
  }

  /// Called when the user presses the close FloatingActionButton.
  /// Simply closes this screen without returning a location.
  void _onCancel() {
    Navigator.pop(context); // return null implicitly
  }

  /// Called whenever the user types in the search bar.
  /// We use a debounce approach: wait 500ms, then call [searchPlacesUseCase].
  void _onSearchChanged(String input) {
    // Cancel any existing debounce timer.
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Start a new debounce.
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final query = input.trim();
      // If empty, clear suggestions.
      if (query.isEmpty) {
        setState(() => _suggestions.clear());
        return;
      }

      // Call the domain's SearchPlacesUseCase to get suggestions.
      final searchUC = ref.read(searchPlacesUseCaseProvider);
      final result = await searchUC.call(params: SearchPlacesParams(query));

      if (!mounted) return;

      if (result is DataSuccess<List<PlaceSuggestionEntity>>) {
        setState(() => _suggestions = result.data!);
      } else {
        setState(() => _suggestions.clear());
      }
    });
  }

  /// Called when the user selects an autocomplete suggestion.
  /// Fetches the final lat/lng via [getPlaceDetailsUseCaseProvider],
  /// moves the marker, and centers the map.
  Future<void> _selectSuggestion(PlaceSuggestionEntity suggestion) async {
    final placeDetailsUC = ref.read(getPlaceDetailsUseCaseProvider);
    final result = await placeDetailsUC.call(params: suggestion.placeId);

    if (!mounted) return;

    if (result is DataSuccess<PlaceDetailsEntity>) {
      final details = result.data!;
      setState(() {
        _pickedLatLng = details.latLng;
        _marker = Marker(
          markerId: const MarkerId('my-marker'),
          position: details.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          draggable: true,
          onDragEnd: (pos) => _pickedLatLng = pos,
        );
        // Update the search bar text to the picked suggestion description.
        _searchController.text = suggestion.description;
        // Clear the suggestions list.
        _suggestions.clear();
      });
      // Move camera to the new location.
      _moveCamera(details.latLng, 16);
    } else if (result is DataFailed<PlaceDetailsEntity>) {
      toast("Failed to fetch place details: ${result.error?.error}");
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no marker is defined yet, pass an empty set.
    final markers = _marker == null ? <Marker>{} : {_marker!};

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            /// 1) Google Map behind everything
            GoogleMap(
              onMapCreated: _onMapCreated,
              onTap: _onMapTap,
              initialCameraPosition: const CameraPosition(
                target: LatLng(0, 0), // Dummy coords; we animate later.
                zoom: 2,
              ),
              markers: markers,
            ),

            /// 2) Search bar at the top
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Column(
                children: [
                  // Search text input
                  Container(
                    decoration: boxDecorationRoundedWithShadow(
                      12,
                      backgroundColor: Colors.white,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Search location...',
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),

                  // Suggestions list
                  if (_suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: boxDecorationRoundedWithShadow(
                        12,
                        backgroundColor: Colors.white,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        itemBuilder: (ctx, i) {
                          final s = _suggestions[i];
                          return ListTile(
                            title: Text(s.description),
                            onTap: () => _selectSuggestion(s),
                          );
                        },
                      ),
                    )
                ],
              ),
            ),

            /// 3) Confirm (check) button at bottom-left
            Positioned(
              bottom: 40,
              left: 10,
              child: FloatingActionButton(
                onPressed: _onConfirm,
                backgroundColor: vPrimaryColor.withOpacity(0.7),
                child: const Icon(
                  Icons.check,
                  color: vAccentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
