// lib/presentation/screens/post/select_location_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../core/resources/data_state.dart';
import '../../../core/util/colors.dart';
import '../../../domain/entities/google_maps/place_details_entity.dart';
import '../../../domain/entities/google_maps/place_location_entity.dart';
import '../../../domain/entities/google_maps/place_suggestion_entity.dart';
import '../../../domain/usecases/google_maps/reverse_geocode_usecase.dart';
import '../../../domain/usecases/google_maps/search_places_usecase.dart';
import '../../providers/google_maps/location_providers.dart';
import '../../providers/post/post_location_provider.dart';
import '../../widgets/navigation/navigation_service.dart';

/// A screen that allows the user to pick a location on a Google Map:
/// - Requests location permission, placing a red marker at the user's current position (if granted).
/// - Lets the user tap or drag the marker to reposition.
/// - Includes a search bar (Autocomplete) for jumping to addresses.
/// - Hides system UI overlays in an immersive mode for a full-screen map experience.
/// - Two floating action buttons:
///   - Left "Confirm" (check): finalizes the chosen LatLng into [postLocationProvider].
///   - (Optional) You could add a "Cancel" if needed, but here we only show confirm as an example.
///
/// Usage:
///   Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectLocationScreen()));
///   // The chosen location is saved in [postLocationProvider].
class SelectLocationScreen extends ConsumerStatefulWidget {
  const SelectLocationScreen({super.key});

  @override
  ConsumerState<SelectLocationScreen> createState() =>
      _SelectLocationScreenState();
}

class _SelectLocationScreenState extends ConsumerState<SelectLocationScreen> {
  /// Controller for the [GoogleMap].
  GoogleMapController? _mapController;

  /// The currently picked location, stored as a [LatLng].
  LatLng? _pickedLatLng;

  /// A marker displayed on the map at [_pickedLatLng], draggable by the user.
  Marker? _marker;

  /// For the search bar input text.
  final TextEditingController _searchController = TextEditingController();

  /// A debounce timer to delay autocomplete calls while the user is typing.
  Timer? _debounce;

  /// Holds autocomplete results from the Places API.
  List<PlaceSuggestionEntity> _suggestions = [];

  @override
  void initState() {
    super.initState();
    // Enter full-immersive mode so the user sees a full-screen map.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // After the initial frame is built, request location.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  @override
  void dispose() {
    // Cancel any scheduled debounce calls.
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Requests the user's current location via [getCurrentLocationUseCaseProvider].
  /// If successful, places a marker and animates the map there.
  /// If it fails, we toast an error message.
  Future<void> _initLocation() async {
    final getLocUseCase = ref.read(getCurrentLocationUseCaseProvider);
    final result = await getLocUseCase();

    if (!mounted) return;

    if (result is DataSuccess<PlaceLocationEntity>) {
      final loc = result.data!;
      setState(() {
        _pickedLatLng = LatLng(loc.latitude, loc.longitude);
        _marker = Marker(
          markerId: const MarkerId('my-marker'),
          position: _pickedLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          draggable: true,
          onDragEnd: (pos) => _pickedLatLng = pos,
        );
      });
      _moveCamera(_pickedLatLng!, 16);
    } else if (result is DataFailed<PlaceLocationEntity>) {
      toast("Failed to get location: ${result.error?.error}");
    }
  }

  /// Animates the map camera to [latLng] at the given [zoom] level.
  void _moveCamera(LatLng latLng, double zoom) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, zoom),
      );
    }
  }

  /// Called when the map is ready. Saves [controller], then re-centers on
  /// any existing [_pickedLatLng].
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_pickedLatLng != null) {
      _moveCamera(_pickedLatLng!, 16);
    }
  }

  /// Called when the user taps the map. Places a marker at [latLng].
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

  /// Confirms the location by optionally reverse-geocoding. Then sets
  /// [postLocationProvider] and pops.
  Future<void> _onConfirm() async {
    if (_pickedLatLng == null) {
      toast("No location selected!");
      return;
    }

    final lat = _pickedLatLng!.latitude;
    final lng = _pickedLatLng!.longitude;

    // Attempt reverse geocoding for an address.
    final reverseUC = ref.read(reverseGeocodeUseCaseProvider);
    final reverseResult = await reverseUC.call(
      params: ReverseGeocodeParams(lat, lng),
    );
    if (!mounted) return;

    String? address;
    if (reverseResult is DataSuccess<String>) {
      address = reverseResult.data;
    }

    // Construct the final location entity, storing address if found.
    final locationEntity = PlaceLocationEntity(
      latitude: lat,
      longitude: lng,
      address: address,
      name: null,
    );

    // Save this to the provider for the rest of the app to see.
    ref.read(postLocationProvider.notifier).state = locationEntity;

    if (!mounted) return;
    ref.read(navigationServiceProvider).navigateBack(context);  }

  /// Triggered whenever the search input changes. Debounced by 500ms.
  void _onSearchChanged(String input) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final query = input.trim();
      if (query.isEmpty) {
        setState(() => _suggestions.clear());
        return;
      }

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

  /// Called when the user picks an autocomplete suggestion from the list.
  /// We then fetch place details (lat/lng) and move the marker/camera there.
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
        _searchController.text = suggestion.description;
        _suggestions.clear();
      });
      _moveCamera(details.latLng, 16);
    } else if (result is DataFailed<PlaceDetailsEntity>) {
      toast("Failed to fetch place details: ${result.error?.error}");
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no marker is defined, pass an empty set to GoogleMap.
    final markers = _marker == null ? <Marker>{} : {_marker!};

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 1) Google Map behind everything
            GoogleMap(
              onMapCreated: _onMapCreated,
              onTap: _onMapTap,
              initialCameraPosition: const CameraPosition(
                target: LatLng(0, 0),
                // Dummy coords; we'll animate after creation
                zoom: 2,
              ),
              markers: markers,
            ),

            // 2) The search bar & suggestions at the top
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Column(
                children: [
                  // Search input
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
                  // Suggestions
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
                    ),
                ],
              ),
            ),

            // 3) Confirm FAB (lower-left)
            Positioned(
              bottom: 40,
              left: 10,
              child: FloatingActionButton(
                onPressed: _onConfirm,
                // Replacing .withOpacity(0.7) => approximate alpha 178
                backgroundColor: vPrimaryColor.withAlpha(178),
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
