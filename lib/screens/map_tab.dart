import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});
  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  late GoogleMapController mapController;
  Set<Marker> marker = {};  
  final LatLng _center = const LatLng(30.445966, -91.1879593);

  // Voter info state
  bool _isLoadingVoterInfo = true;
  String? _voterWard;
  String? _voterParish;
  String? _voterStatus;
  String? _votingLocationName;
  String? _votingLocationAddress;
  LatLng? _votingLocationCoords;
  String? _errorMessage;

  Color get primaryLavender => const Color(0xFFF4F0FB);
  Color get accentPurple => const Color(0xFFB48CFB);
  Color get textDark => const Color(0xFF3D3A50);

  @override
  void initState() {
    super.initState();
    _loadVoterInfo();
  }

  /// Load voter information from Firestore
  Future<void> _loadVoterInfo() async {
    setState(() {
      _isLoadingVoterInfo = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Please log in to view voter information';
          _isLoadingVoterInfo = false;
        });
        return;
      }

      // Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        setState(() {
          _errorMessage = 'User data not found';
          _isLoadingVoterInfo = false;
        });
        return;
      }

      final userData = userDoc.data()!;

      // Check if we have voter registration data
      if (userData['voter_ward_precinct'] != null) {
        // User already has voter info cached in Firestore
        setState(() {
          _voterWard = userData['voter_ward_precinct'];
          _voterParish = userData['voter_parish'];
          _voterStatus = userData['voter_status'];
          
          // Get voting location if cached
          _votingLocationName = userData['voting_location_name'];
          _votingLocationAddress = userData['voting_location_address'];
          
          // Parse coordinates if available
          if (userData['voting_location_lat'] != null && 
              userData['voting_location_lng'] != null) {
            _votingLocationCoords = LatLng(
              userData['voting_location_lat'],
              userData['voting_location_lng'],
            );
          }
          
          _isLoadingVoterInfo = false;
        });

        // Add marker for voting location if we have coords
        if (_votingLocationCoords != null) {
          _addVotingLocationMarker();
        }
      } else {
        // No voter info yet - check if they have registration data
        if (userData['zip_code'] == null || 
            userData['birth_month'] == null || 
            userData['birth_year'] == null) {
          setState(() {
            _errorMessage = 'Please update your profile with voter registration info';
            _isLoadingVoterInfo = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Voter information not yet fetched. Please refresh.';
            _isLoadingVoterInfo = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading voter info: ${e.toString()}';
        _isLoadingVoterInfo = false;
      });
    }
  }

  /// Add marker for voting location on map
  void _addVotingLocationMarker() {
    if (_votingLocationCoords == null) return;

    marker.add(
      Marker(
        markerId: const MarkerId('votingLocation'),
        position: _votingLocationCoords!,
        infoWindow: InfoWindow(
          title: _votingLocationName ?? 'Your Voting Location',
          snippet: _votingLocationAddress ?? '',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    // Center map on voting location
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _votingLocationCoords!,
              zoom: 15.0,
            ),
          ),
        );
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryLavender,
      appBar: AppBar(
        backgroundColor: primaryLavender,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Lawgic',
          style: TextStyle(
            color: textDark,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: textDark),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textDark),
            onPressed: _loadVoterInfo,
            tooltip: 'Refresh voter info',
          ),
        ],
      ),

      drawer: Drawer(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: accentPurple.withOpacity(0.15)),
              child: Center(
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _drawerItem(Icons.settings_outlined, 'Settings'),
            _drawerItem(Icons.notifications_outlined, 'Notifications'),
            _drawerItem(Icons.history, 'Recently Viewed'),
            _drawerItem(Icons.info_outline, 'About'),
          ],
        ),
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 450,
              width: double.infinity,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: GoogleMap(
                        myLocationButtonEnabled: false,
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          target: _votingLocationCoords ?? _center,
                          zoom: _votingLocationCoords != null ? 15.0 : 11.0,
                        ),
                        markers: marker,
                      ),
                    ),
                  ),
                  
                  Positioned(
                    top: 8,
                    right: 8,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: () async {
                        try {
                          Position position = await userPosition();
                          mapController.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(position.latitude, position.longitude),
                                zoom: 15.0,
                              ),
                            ),
                          );
                          
                          marker.removeWhere((m) => m.markerId.value == 'currentLocation');
                          marker.add(
                            Marker(
                              markerId: const MarkerId('currentLocation'),
                              position: LatLng(position.latitude, position.longitude),
                              infoWindow: const InfoWindow(title: 'Your Location'),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed
                              ),
                            ),
                          );
                          setState(() {});
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Icon(Icons.my_location, color: Colors.blue),
                    ),
                  ),
                  
                  if (_isLoadingVoterInfo)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black),
              ),
              child: _isLoadingVoterInfo
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _errorMessage != null
                      ? Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        )
                      : Text(
                          _voterWard != null 
                              ? 'Your voting ward: $_voterWard'
                              : 'Ward information not available',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
            ),
            
            const SizedBox(height: 8),
            
            Container(
              constraints: const BoxConstraints(minHeight: 130),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blueGrey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isLoadingVoterInfo
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Text(
                            'Voting location not available',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Voting Location:',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _votingLocationName ?? 'Not available',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _votingLocationAddress ?? '',
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: textDark),
      title: Text(title, style: TextStyle(color: textDark)),
      onTap: () {},
    );
  }

  Future<Position> userPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) { 
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.'
      );
    }

    Position position = await Geolocator.getCurrentPosition();
    return position;
  }
}