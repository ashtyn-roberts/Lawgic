import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';



class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}
class _MapTabState extends State<MapTab> {
  Color? get primaryLavender => null;
  Color? get textDark => null;
  late GoogleMapController mapController;
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
          
          Text(
            'Voting Locations',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 350,
            width: double.infinity,
            child: GoogleMap( 
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            )
          ),
          ),
          
          SizedBox(height: 20),
          Text(
            'Welcome *Username*',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Your voting ward: xx/xxx',
            style: TextStyle(
              fontSize: 22,
              color: Colors.grey,
            ),
          ),
          Text(
            'Location: *Building Name*',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey,
            ),
          ),
          Text(
            'Address: *Building Address*',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 32),
          Text(
            'Open in Google Maps',
            style: TextStyle(
              fontSize : 24,
              color: Colors.red[600],
            ))
        ],
      ),
    ), 
    );
  }
}
