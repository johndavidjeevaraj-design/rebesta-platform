import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/address.dart';
import '../../../services/location_service.dart';
import '../../../services/geocoding_service.dart';
import '../../../services/address_service.dart';

class AddAddressScreen extends StatefulWidget {
  final Address? address;

  const AddAddressScreen({
    super.key,
    this.address,
  });

  @override
  State<AddAddressScreen> createState() =>
      _AddAddressScreenState();
}

class _AddAddressScreenState
    extends State<AddAddressScreen> {
  // ============================================================
  // SERVICES
  // ============================================================

  final MapController _mapController =
      MapController();

  final LocationService _locationService =
      LocationService();

  final GeocodingService _geocodingService =
      GeocodingService();

  final AddressService _addressService =
      AddressService();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _addressController =
      TextEditingController();

  // ============================================================
  // LOCATION
  // ============================================================

  LatLng currentLocation = const LatLng(
    12.9716,
    77.5946,
  );

  LatLng selectedLocation = const LatLng(
    12.9716,
    77.5946,
  );

  // ============================================================
  // STATE
  // ============================================================

  bool loadingLocation = true;
  bool loadingAddress = false;
  bool savingAddress = false;

  String selectedAddress = '';

  String selectedType = 'Home';

  final List<String> addressTypes = [
    'Home',
    'Work',
    'Other',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
void initState() {
  super.initState();

  final existingAddress = widget.address;

  if (existingAddress != null) {
    // EDIT MODE
    selectedType = existingAddress.title;

    if (!addressTypes.contains(selectedType)) {
      selectedType = 'Other';
    }

    selectedAddress = existingAddress.address;

    _addressController.text =
        existingAddress.address;

    selectedLocation = LatLng(
      existingAddress.latitude,
      existingAddress.longitude,
    );

    currentLocation = selectedLocation;

    loadingLocation = false;
    loadingAddress = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.move(
          selectedLocation,
          17,
        );
      }
    });
  } else {
    // ADD MODE
    loadCurrentLocation();
  }
}
  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _addressController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD CURRENT LOCATION
  // ============================================================

  Future<void> loadCurrentLocation() async {
    try {
      final Position position =
          await _locationService
              .getCurrentLocation();

      currentLocation = LatLng(
        position.latitude,
        position.longitude,
      );

      selectedLocation = currentLocation;

      await loadAddress();

      if (!mounted) return;

      setState(() {
        loadingLocation = false;
      });

      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(
            currentLocation,
            17,
          );
        }
      });
    } catch (e) {
      debugPrint(
        'LOCATION ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        loadingLocation = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to get your location',
            style: GoogleFonts.sora(),
          ),
        ),
      );
    }
  }

  // ============================================================
  // LOAD ADDRESS FROM COORDINATES
  // ============================================================

  Future<void> loadAddress() async {
    if (!mounted) return;

    setState(() {
      loadingAddress = true;
    });

    try {
      final address =
          await _geocodingService.getAddress(
        selectedLocation.latitude,
        selectedLocation.longitude,
      );

      if (!mounted) return;

      setState(() {
        selectedAddress = address;
        _addressController.text = address;
        loadingAddress = false;
      });
    } catch (e) {
      debugPrint(
        'GEOCODING ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        loadingAddress = false;
        selectedAddress =
            'Unable to detect address';
      });
    }
  }

  // ============================================================
  // MAP MOVED
  // ============================================================

  Future<void> _onMapMoved(
    MapCamera camera,
    bool hasGesture,
  ) async {
    if (!hasGesture) return;

    selectedLocation = camera.center;

    await loadAddress();
  }

  // ============================================================
  // MOVE TO CURRENT LOCATION
  // ============================================================

  Future<void> _goToCurrentLocation() async {
    try {
      final Position position =
          await _locationService
              .getCurrentLocation();

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        currentLocation = location;
        selectedLocation = location;
      });

      _mapController.move(
        location,
        17,
      );

      await loadAddress();
    } catch (e) {
      debugPrint(
        'CURRENT LOCATION ERROR: $e',
      );
    }
  }

  // ============================================================
  // SAVE ADDRESS
  // ============================================================

  Future<void> _saveAddress() async {
    if (savingAddress) return;

    final address =
        _addressController.text.trim();

    if (address.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Please select an address'),
        ),
      );

      return;
    }

    setState(() {
      savingAddress = true;
    });

    try {
      final Address? saved;

if (widget.address == null) {
  // ==========================================================
  // ADD NEW ADDRESS
  // ==========================================================

  saved = await _addressService.saveAddress(
    title: selectedType,
    address: address,
    latitude: selectedLocation.latitude,
    longitude: selectedLocation.longitude,
  );
} else {
  // ==========================================================
  // UPDATE EXISTING ADDRESS
  // ==========================================================

  saved = await _addressService.updateAddress(
    addressId: widget.address!.id,
    title: selectedType,
    address: address,
    latitude: selectedLocation.latitude,
    longitude: selectedLocation.longitude,
  );
}

      if (!mounted) return;

      setState(() {
        savingAddress = false;
      });

      if (saved != null) {
        context.pop(saved);
      } else {
        context.pop(true);
      }
    } catch (e) {
      debugPrint(
        'SAVE ADDRESS ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        savingAddress = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFCF9F5),

      body: loadingLocation
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Stack(
              children: [
                _buildMap(),
                _buildCenterPin(),
                _buildTopBar(),
                _buildCurrentLocationButton(),
                _buildBottomSheet(),
              ],
            ),
    );
  }

  // ============================================================
  // MAP
  // ============================================================

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,

      options: MapOptions(
        initialCenter: currentLocation,
        initialZoom: 17,

        onPositionChanged:
            _onMapMoved,
      ),

      children: [
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

          userAgentPackageName:
              'com.rebesta.customer',
        ),
      ],
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context)
              .padding
              .top +
          10,

      left: 16,
      right: 16,

      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,

            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                14,
              ),

              boxShadow: const [
                BoxShadow(
                  color:
                      Color(0x22000000),
                  blurRadius: 12,
                  offset:
                      Offset(0, 4),
                ),
              ],
            ),

            child: IconButton(
              onPressed: () {
                context.pop();
              },

              icon: const Icon(
                Icons
                    .arrow_back_rounded,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Container(
              height: 44,

              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 16,
              ),

              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),

                boxShadow: const [
                  BoxShadow(
                    color:
                        Color(0x22000000),
                    blurRadius: 12,
                    offset:
                        Offset(0, 4),
                  ),
                ],
              ),

              alignment:
                  Alignment.centerLeft,

              child: Text(
                'Choose delivery location',

                style:
                    GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      const Color(
                    0xFF2A1D1A,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CURRENT LOCATION BUTTON
  // ============================================================

  Widget _buildCurrentLocationButton() {
    return Positioned(
      right: 18,

      bottom: 330,

      child: GestureDetector(
        onTap:
            _goToCurrentLocation,

        child: Container(
          width: 48,
          height: 48,

          decoration:
              BoxDecoration(
            color: Colors.white,

            shape: BoxShape.circle,

            boxShadow: const [
              BoxShadow(
                color:
                    Color(0x22000000),
                blurRadius: 12,
                offset:
                    Offset(0, 4),
              ),
            ],
          ),

          child: const Icon(
            Icons
                .my_location_rounded,

            color:
                Color(0xFFFF6C0E),

            size: 22,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CENTER PIN
  // ============================================================

  Widget _buildCenterPin() {
    return const Center(
      child: Padding(
        padding:
            EdgeInsets.only(
          bottom: 30,
        ),

        child: Icon(
          Icons.location_pin,

          size: 55,

          color:
              Color(0xFFFF3B30),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM SHEET
  // ============================================================

  Widget _buildBottomSheet() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,

      child: SafeArea(
        top: false,

        child: Container(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            16,
          ),

          decoration:
              const BoxDecoration(
            color:
                Color(0xFFFCF9F5),

            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(28),
            ),

            boxShadow: [
              BoxShadow(
                color:
                    Color(0x22000000),
                blurRadius: 20,
                offset:
                    Offset(0, -5),
              ),
            ],
          ),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ==================================================
              // HANDLE
              // ==================================================

              Center(
                child: Container(
                  width: 38,
                  height: 4,

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFD8D1C9,
                    ),

                    borderRadius:
                        BorderRadius
                            .circular(
                      10,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              Text(
                'Where should we deliver?',
                style:
                    GoogleFonts
                        .bricolageGrotesque(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      const Color(
                    0xFF2A1D1A,
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // ADDRESS
              // ==================================================

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets
                        .all(14),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),

                  border:
                      Border.all(
                    color:
                        const Color(
                      0xFFEFEAE2,
                    ),
                  ),
                ),

                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    const Icon(
                      Icons
                          .location_on_rounded,

                      color:
                          Color(
                        0xFFFF6C0E,
                      ),

                      size: 22,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child:
                          loadingAddress
                              ? const Text(
                                  'Finding address...',
                                )
                              : Text(
                                  selectedAddress
                                          .isEmpty
                                      ? 'Move the map to select a location'
                                      : selectedAddress,

                                  maxLines: 3,

                                  overflow:
                                      TextOverflow
                                          .ellipsis,

                                  style:
                                      GoogleFonts
                                          .sora(
                                    fontSize:
                                        12,

                                    height:
                                        1.45,

                                    color:
                                        const Color(
                                      0xFF70625F,
                                    ),
                                  ),
                                ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // ==================================================
              // ADDRESS TYPE
              // ==================================================

              Text(
                'SAVE AS',
                style:
                    GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing:
                      0.5,
                  color:
                      const Color(
                    0xFF70625F,
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Row(
                children:
                    addressTypes.map(
                  (type) {
                    final selected =
                        selectedType ==
                            type;

                    return Expanded(
                      child:
                          Padding(
                        padding:
                            EdgeInsets.only(
                          right:
                              type ==
                                      'Other'
                                  ? 0
                                  : 8,
                        ),

                        child:
                            GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedType =
                                  type;
                            });
                          },

                          child:
                              AnimatedContainer(
                            duration:
                                const Duration(
                              milliseconds:
                                  180,
                            ),

                            height: 42,

                            decoration:
                                BoxDecoration(
                              color:
                                  selected
                                      ? const Color(
                                          0xFFFF6C0E,
                                        )
                                      : Colors
                                          .white,

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),

                              border:
                                  Border.all(
                                color:
                                    selected
                                        ? const Color(
                                            0xFFFF6C0E,
                                          )
                                        : const Color(
                                            0xFFEFEAE2,
                                          ),
                              ),
                            ),

                            child:
                                Center(
                              child:
                                  Text(
                                type,

                                style:
                                    GoogleFonts
                                        .sora(
                                  fontSize:
                                      12,

                                  fontWeight:
                                      FontWeight
                                          .w700,

                                  color:
                                      selected
                                          ? Colors
                                              .white
                                          : const Color(
                                              0xFF2A1D1A,
                                            ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),

              const SizedBox(
                height: 14,
              ),

              // ==================================================
              // SAVE
              // ==================================================

              SizedBox(
                width:
                    double.infinity,

                height: 54,

                child:
                    ElevatedButton(
                  onPressed:
                      savingAddress ||
                              loadingAddress ||
                              selectedAddress
                                  .isEmpty
                          ? null
                          : _saveAddress,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFFFF6C0E,
                    ),

                    disabledBackgroundColor:
                        const Color(
                      0xFFE5E1DC,
                    ),

                    elevation: 0,

                    shape:
                        const StadiumBorder(),
                  ),

                  child: savingAddress
                      ? const SizedBox(
                          width: 22,
                          height: 22,

                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2.5,
                            color:
                                Colors.white,
                          ),
                        )
                      : Text(
                          widget.address == null
                              ? 'Save address'
                              : 'Update address',

                          style:
                              GoogleFonts.sora(
                            fontSize:
                                15,
                            fontWeight:
                                FontWeight.w700,
                            color:
                                Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}