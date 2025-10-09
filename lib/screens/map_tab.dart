import 'package:flutter/material.dart';

class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          SizedBox(height: 32),
          Container(
            width:400,
            height:350,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border:Border.all(color: Colors.black, width: 2)
            ),),
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
    ); 
  }
}
