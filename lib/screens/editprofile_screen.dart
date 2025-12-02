import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _usernameController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  Uint8List? _image;
  String? _imageUrl;

  bool _isLoading = true;
  bool _saving = false;
  String? _error;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _loadUserData();
  }

  @override
  void dispose() {
    _isMounted = false;
    _usernameController.dispose();
    _firstnameController.dispose();
    _lastnameController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (_isMounted) {
      setState(fn);
    }
  }

// creates imagepicker that allows users to pick an image from a source 
  Future<Uint8List?> pickImage(ImageSource source ) async{
  final ImagePicker imagePicker = ImagePicker();
  XFile? file = await imagePicker.pickImage(source: source);

  if(file != null) {
    return await file.readAsBytes();
  }
  print('No Image Seleted');
  return null;
 }

  bool _isPickingImage = false;

// uses imagepicker to allow users to select an image from device gallery 
  Future<void> selectImage() async{
    if (_isPickingImage) return; // Prevent multiple simultaneous picks
    _isPickingImage = true;
    try {
      final Uint8List? img = await pickImage(ImageSource.gallery);
      if (img != null && mounted) {
        setState(() {
          _image = img;
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      
    } finally {
      _isPickingImage = false;
    }
  }

  // stores image to firebase storage and returns the download url
  Future<String> uploadImage(String uid, Uint8List file) async {
    Reference ref =  FirebaseStorage.instance
    .ref()
    .child('profilePics')
    .child('$uid.jpg');

    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }



  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _safeSetState(() {
        _error = "You are signed out.";
        _isLoading = false;
      });
      return;
    }

    try {

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _usernameController.text = data['username']?.toString() ?? '';
        _firstnameController.text = data['first_name']?.toString() ?? '';
        _lastnameController.text = data['last_name']?.toString() ?? '';
        _imageUrl = data['ProfilePicUrl'] ?? '';


        
      }
    } catch (e) {
      _safeSetState(() {
        _error = "Failed to load user data";
        _isLoading = false;
      });
      return;
    }

    _safeSetState(() {
      _isLoading = false;
      _error = null;
    });
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _safeSetState(() {
        _error = "You are signed out.";
      });
      return;
    }

    // Validation
    if (_usernameController.text.trim().isEmpty ||
        _firstnameController.text.trim().isEmpty ||
        _lastnameController.text.trim().isEmpty) {
      _safeSetState(() => _error = "All fields are required.");
      return;
    }

    _safeSetState(() {
      _saving = true;
      _error = null;
    });

    try {

      if (_image != null) {
        _imageUrl = await uploadImage(user.uid, _image!);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
            'username': _usernameController.text.trim(),
            'first_name': _firstnameController.text.trim(),
            'last_name': _lastnameController.text.trim(),
            'ProfilePicUrl': _imageUrl != null
                ? "${_imageUrl!}?v=${DateTime.now().millisecondsSinceEpoch}"
                : '',
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // SUCCESS - Navigate back to profile
      if (_isMounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            duration: Duration(seconds: 1),
          )
        );
        
        // Use a small delay to ensure the snackbar is visible
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Simply pop back to the previous screen (ProfileTab)
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (_isMounted) {
        _safeSetState(() {
          _error = "Failed to save profile: $e";
          _saving = false;
        });
      }
    }
  }

  
  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14), 
         borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.blue, width: 1.5 ),
      ),
      labelStyle: TextStyle(
        color: Colors.grey[700],
        fontSize: 14,
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Picture Placeholder
                  GestureDetector(
                    onTap: selectImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _image != null
                          ? MemoryImage(_image!) 
                          : (_imageUrl != null && _imageUrl!.isNotEmpty
                              ? NetworkImage("${_imageUrl!}?v=${DateTime.now().millisecondsSinceEpoch}") 
                              : const AssetImage('images/sleepyjoe.jpg') as ImageProvider),
                      child:  (_image == null && (_imageUrl == null || _imageUrl!.isEmpty))
                          ? const Icon(Icons.add_a_photo, size: 30, color: Colors.grey)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  // Form Fields
                  TextField(
                    controller: _firstnameController,
                    decoration: _inputStyle( "First Name"),
                  ),

                  const SizedBox(height: 20),
                 
                  TextField(
                    controller: _lastnameController,
                    decoration: _inputStyle('Last Name'),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: _usernameController,
                    decoration: _inputStyle('Username'),
                  ),
                  
                  
                  // Error Message
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  // Save Button
                  _saving
                      ? const Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Saving...'),
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            child: const Text("Save Changes"),
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}