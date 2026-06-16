// lib/presentation/screens/client/create_order_wizard/steps/step_address.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../providers/order_wizard_provider.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_button.dart';

class StepAddress extends StatefulWidget {
  final OrderWizardNotifier notifier;
  final OrderWizardState state;
  final VoidCallback? onStateChanged;

  const StepAddress({
    super.key,
    required this.notifier,
    required this.state,
    this.onStateChanged,
  });

  @override
  State<StepAddress> createState() => _StepAddressState();
}

class _StepAddressState extends State<StepAddress> {
  GoogleMapController? _mapController;
  final TextEditingController _addressController = TextEditingController();
  late LatLng _selectedLocation;
  Set<Marker> _markers = {};
  bool _isLoading = false;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(43.238293, 76.945465),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.state.address;
    _selectedLocation = widget.state.address.isNotEmpty
        ? const LatLng(43.238293, 76.945465) // временно, потом обновится через геокодинг
        : const LatLng(43.238293, 76.945465);

    if (widget.state.address.isNotEmpty) {
      _geocodeAddress(widget.state.address);
    }
    _getCurrentLocation();
  }

  @override
  void didUpdateWidget(StepAddress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.address != widget.state.address && widget.state.address.isNotEmpty) {
      _addressController.text = widget.state.address;
    }
  }

  void _updateState() {
    widget.onStateChanged?.call();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пожалуйста, включите геолокацию')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _updateMarker();
      });

      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _selectedLocation, zoom: 15),
          ),
        );
      }

      await _updateAddressFromLocation();
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _geocodeAddress(String address) async {
    setState(() => _isLoading = true);
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        setState(() {
          _selectedLocation = LatLng(locations.first.latitude, locations.first.longitude);
          _updateMarker();
        });
        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _selectedLocation, zoom: 15),
            ),
          );
        }
      }
    } catch (e) {
      print('Error geocoding address: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAddressFromLocation() async {
    setState(() => _isLoading = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String address = [
          place.street,
          place.subLocality,
          place.locality,
          place.country,
        ].where((part) => part != null && part.isNotEmpty).join(', ');
        setState(() {
          _addressController.text = address;
        });
        widget.notifier.updateAddress(address);
        _updateState();
      }
    } catch (e) {
      print('Error getting address from location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateMarker() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: _selectedLocation,
          infoWindow: const InfoWindow(title: 'Выбранное место'),
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _selectedLocation = newPosition;
              _updateMarker();
            });
            _updateAddressFromLocation();
          },
        ),
      };
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _searchAddress() async {
    if (_addressController.text.isEmpty) return;
    await _geocodeAddress(_addressController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Где провести уборку?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите точку на карте или введите адрес',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _addressController,
                  label: 'Адрес',
                  hint: 'Введите адрес',
                  prefixIcon: Icons.location_on_outlined,
                  onChanged: (value) {
                    widget.notifier.updateAddress(value);
                    _updateState();
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _searchAddress,
                icon: const Icon(Icons.search),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: _initialPosition,
                    markers: _markers,
                    onTap: (latLng) {
                      setState(() {
                        _selectedLocation = latLng;
                        _updateMarker();
                      });
                      _updateAddressFromLocation();
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                  ),
                  if (_isLoading)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  onPressed: _getCurrentLocation,
                  text: 'Мое местоположение',
                  isOutlined: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Вы можете перемещать маркер на карте для точного указания места',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}