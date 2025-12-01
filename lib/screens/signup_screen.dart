import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback onTap;
  const SignUpScreen({super.key, required this.onTap});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  
  //Voter registration fields
  final _zipCodeController = TextEditingController();
  int? _selectedBirthMonth;
  final _birthYearController = TextEditingController();
  
  Uint8List? _image;
  String? _errorMessage;
  bool _isLoading = false;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  // user creation in Firebase Auth and profile creation in Firestore
  Future<void> _signUp() async {
    // Basic validation
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _usernameController.text.isEmpty || 
        _firstnameController.text.isEmpty || 
        _lastnameController.text.isEmpty ||
        _zipCodeController.text.isEmpty ||
        _selectedBirthMonth == null ||
        _birthYearController.text.isEmpty) {
      if (!mounted) return;
      setState(() => _errorMessage = 'All fields are required.');
      return;
    }

    // Validate ZIP code
    if (_zipCodeController.text.length != 5) {
      if (!mounted) return;
      setState(() => _errorMessage = 'ZIP code must be 5 digits.');
      return;
    }

    // Validate birth year
    final birthYear = int.tryParse(_birthYearController.text);
    if (birthYear == null || birthYear < 1900 || birthYear > DateTime.now().year - 18) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Please enter a valid birth year (must be 18+).');
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // create the user in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // create a user profile document in Firestore
      await _createFirestoreUserProfile(userCredential.user!);
      
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else {
        message = 'Sign Up Failed: ${e.message}';
      }
      if (!mounted) return;
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // creates imagepicker that allows users to pick an image from a source 
  Future<Uint8List?> pickImage(ImageSource source) async {
    final ImagePicker imagePicker = ImagePicker();
    XFile? file = await imagePicker.pickImage(source: source);

    if (file != null) {
      return await file.readAsBytes();
    }
    print('No Image Selected');
    return null;
  }

  // uses imagepicker to allow users to select an image from device gallery 
  Future<void> selectImage() async {
    Uint8List? img = await pickImage(ImageSource.gallery);
    if (img != null) {
      if (!mounted) return;
      setState(() {
        _image = img;
      });
    }
  }

  // stores image to firebase storage and returns the download url
  Future<String> uploadImage(String uid, Uint8List file) async {
    Reference ref = FirebaseStorage.instance.ref().child('profilePics').child('$uid.jpg');
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  /// save user's username + email + voter registration info to the users collection
  Future<void> _createFirestoreUserProfile(User user) async {
    final firestore = FirebaseFirestore.instance;
    
    // upload profile image if available if not it will be null(empty)
    String? imageUrl;
    if (_image != null) {
      imageUrl = await uploadImage(user.uid, _image!); // download url is stored in imageUrl
    }

    await firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'username': _usernameController.text.trim(),
      'email': user.email,
      'first_name': _firstnameController.text.trim(),
      'last_name': _lastnameController.text.trim(),
      'ProfilePicUrl': imageUrl, // can be null if no image was selected
      //Voter registration fields
      'zip_code': _zipCodeController.text.trim(),
      'birth_month': _selectedBirthMonth,
      'birth_year': int.parse(_birthYearController.text.trim()),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _firstnameController.dispose();
    _lastnameController.dispose();
    _zipCodeController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lawgic Sign Up'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 40),

              // profile image selection
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 64,
                      backgroundImage: _image != null
                          ? MemoryImage(_image!)
                          : const AssetImage('images/sleepyjoe.jpg') as ImageProvider,
                    ),
                    Positioned(
                      bottom: -10,
                      right: -10,
                      child: IconButton(
                        icon: const Icon(Icons.add_a_photo),
                        onPressed: selectImage,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              //Personal Information Section
              Text(
                'Personal Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
              const SizedBox(height: 16),

              // first_name input
              TextField(
                controller: _firstnameController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  hintText: 'First Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              // last_name input
              TextField(
                controller: _lastnameController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  hintText: 'Last Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              // username input
              TextField(
                controller: _usernameController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'JohnDoe',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 24),

              // Account Information Section
              Text(
                'Account Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
              const SizedBox(height: 16),

              // email input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'user@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // password input
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: '••••••••',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),

              // Voter Registration Section
              Text(
                'Voter Registration Info',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'We use this to verify your voter registration status',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 16),

              // ZIP Code input
              TextField(
                controller: _zipCodeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                decoration: const InputDecoration(
                  labelText: 'ZIP Code',
                  hintText: '70817',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Birth Month Dropdown
              DropdownButtonFormField<int>(
                value: _selectedBirthMonth,
                decoration: const InputDecoration(
                  labelText: 'Birth Month',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                items: List.generate(12, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text(_months[index]),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    _selectedBirthMonth = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Birth Year input
              TextField(
                controller: _birthYearController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: const InputDecoration(
                  labelText: 'Birth Year',
                  hintText: '2003',
                  prefixIcon: Icon(Icons.event_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // sign up button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _signUp,
                      child: const Text('Sign Up'),
                    ),
              const SizedBox(height: 16),

              // Privacy notice
              Text(
                'By creating an account, you agree to our Terms of Service and Privacy Policy. Your voter registration information is used solely for verification purposes.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // switch to sign in
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: widget.onTap,
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Color(0xFF1E88E5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}