import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';



class MapTab extends StatefulWidget {
  const MapTab({super.key});
  @override
  State<MapTab> createState() => _MapTabState();
}


class _MapTabState extends State<MapTab> {
  Color? get primaryLavender => null;
  Color? get textDark => null;
  late GoogleMapController mapController;
  Set<Marker> marker = {};  
  final LatLng _center = const LatLng(30.445966, -91.1879593);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          PopupMenuButton<String>(
            icon: Icon(Icons.person_outline, color: textDark),
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Account', child: Text('Account')),
              const PopupMenuItem(value: 'Registration Status', child: Text('Registration Status')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'Sign Out', child: Text('Sign Out')),
            ],
          ),
        ],
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
                        target: _center,
                        zoom: 11.0,
                      ),
                      markers: {...marker, const Marker(
                        markerId: MarkerId('City hall'),
                        position: LatLng(30.445966, -91.1879593),
                      )},
                    ),
                  ),
                ),
          Positioned(
                  top: 8,
                 right: 8,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: () async {
                      Position position = await userPosition();
                      mapController.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: LatLng(position.latitude, position.longitude),
                          ),
                        ),
                      );
                      marker.clear();
                      marker.add(
                        Marker(
                          markerId: const MarkerId('currentLocation'),
                          position: LatLng(position.latitude, position.longitude),
                        ),
                      );
                      setState(() {});
                    },
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          SizedBox(height: 8),
           Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black),
            ),
            child: const Text(
              'Your voting ward: 003/135',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                color: Colors.black,
              ),
            ),
          ),
        
          
          // Location bubble
          Container(
            height: 130,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blueGrey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                'Nearest Voting Location:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
                Text(
                  'Baton Rouge City Hall',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '233 St Louis St',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),   
        ]
      )
      )
        ]
      )
      )
    );
    
  }

  //Error handling
  Future<Position> userPosition() async{
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!serviceEnabled){
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied){ 
      permission = await Geolocator.requestPermission();
      if(permission == LocationPermission.denied){
        return Future.error('Location permissions are denied');
      }
    }
    if(permission == LocationPermission.deniedForever){
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition();
    return position;
    

}
}



