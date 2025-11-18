import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';



class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}
class _MapTabState extends State<MapTab> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(30.445966, -91.1879593);

  Color get primaryLavender => const Color(0xFFF4F0FB);
  Color get accentPurple => const Color(0xFFB48CFB);
  Color get textDark => const Color(0xFF3D3A50);

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
              decoration:
                  BoxDecoration(color: accentPurple.withOpacity(0.15)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voting Locations',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
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
          
        const SizedBox(height: 20),
          Text(
            'Welcome *Username*',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textDark,
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
          const SizedBox(height: 32),
          Text(
            'Open in Google Maps',
            style: TextStyle(
              fontSize : 24,
              color: Colors.red[600],
              decoration: TextDecoration.underline,
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
      onTap: () {
        // TODO: implement navigation for map drawer
      },
    );
  }
}
