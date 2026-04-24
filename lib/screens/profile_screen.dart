import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserRepository _userRepository = UserRepository();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  final _nameController = TextEditingController();
  String? _gender;
  DateTime? _birthday;
  String? _country;
  String? _currencyCode;
  String? _profilePicUrl;
  String? _coverPicUrl;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isProfile) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final String fileName = isProfile ? 'profile_pic' : 'cover_pic';
      final fileNameSaved = await _userRepository.saveLocalImage(File(image.path), fileName);
      
      if (fileNameSaved != null) {
        setState(() {
          if (isProfile) {
            _profilePicUrl = fileNameSaved;
          } else {
            _coverPicUrl = fileNameSaved;
          }
        });
        await _saveProfile();
      } else {
        throw 'Failed to save image locally.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectBirthday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthday) {
      setState(() {
        _birthday = picked;
      });
      _saveProfile();
    }
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        setState(() {
          _country = country.name;
          // country_picker does not have currencyCode, we use a simple mapping or placeholder
          _currencyCode = _getCurrencyForCountry(country.countryCode);
        });
        _saveProfile();
      },
    );
  }

  Future<void> _saveProfile() async {
    final user = UserModel(
      uid: _userRepository.uid,
      name: _nameController.text.trim(),
      gender: _gender,
      birthday: _birthday,
      country: _country,
      currencyCode: _currencyCode,
      profilePicUrl: _profilePicUrl,
      coverPicUrl: _coverPicUrl,
    );
    await _userRepository.saveUserData(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<UserModel?>(
        stream: _userRepository.getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user != null && !_isInitialized) {
            _nameController.text = user.name;
            _gender = user.gender;
            _birthday = user.birthday;
            _country = user.country;
            _currencyCode = user.currencyCode;
            _profilePicUrl = user.profilePicUrl;
            _coverPicUrl = user.coverPicUrl;
            _isInitialized = true;
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildProfileInfo(user),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() => _isLoading = true);
                          try {
                            await _saveProfile();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profile saved successfully!')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to save profile: $e'), backgroundColor: Colors.red),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text("Save Profile"),
                      ),
                      const SizedBox(height: 24),
                      _buildEditFields(),
                      const SizedBox(height: 32),
                      _buildSignOutButton(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover Image
            GestureDetector(
              onTap: () => _pickImage(false),
              child: _coverPicUrl != null
                  ? FutureBuilder<String>(
                      future: _userRepository.getLocalPath(_coverPicUrl!),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.file(File(snapshot.data!), fit: BoxFit.cover);
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.add_a_photo, color: Colors.white54, size: 40),
                      ),
                    ),
            ),
            // Profile Pic
            Positioned(
              bottom: 10,
              left: 20,
              child: GestureDetector(
                onTap: () => _pickImage(true),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: _profilePicUrl != null
                      ? FutureBuilder<String>(
                          future: _userRepository.getLocalPath(_profilePicUrl!),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return CircleAvatar(
                                radius: 45,
                                backgroundImage: FileImage(File(snapshot.data!)),
                              );
                            }
                            return const CircleAvatar(radius: 45);
                          },
                        )
                      : const CircleAvatar(
                          radius: 45,
                          child: Icon(Icons.person, size: 50),
                        ),
                ),
              ),
            ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(UserModel? user) {
    return Column(
      children: [
        Text(
          _nameController.text.isNotEmpty ? _nameController.text : "Add Name",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (user != null && user.birthday != null)
          Text(
            "Age: ${user.age} years",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        if (_country != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                const SizedBox(width: 4),
                Text("$_country ($_currencyCode)", style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEditFields() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              // Removed onChanged to prevent overloading and potential hangs during typing
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.wc),
              title: const Text("Gender"),
              trailing: DropdownButton<String>(
                value: _gender,
                hint: const Text("Select"),
                items: ["Male", "Female", "Other"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _gender = val);
                  _saveProfile();
                },
              ),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cake_outlined),
              title: const Text("Birthday"),
              subtitle: Text(_birthday == null ? "Not set" : DateFormat('MMM dd, yyyy').format(_birthday!)),
              onTap: () => _selectBirthday(context),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.public),
              title: const Text("Currency / Country"),
              subtitle: Text(_country ?? "Select your country"),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showCountryPicker,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _confirmSignOut(context),
        icon: const Icon(Icons.logout),
        label: const Text("Sign Out"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home
              await _authService.signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  String _getCurrencyForCountry(String countryCode) {
    final Map<String, String> currencyMap = {
      'US': 'USD',
      'GB': 'GBP',
      'BD': 'BDT',
      'IN': 'INR',
      'EU': 'EUR',
      'CA': 'CAD',
      'AU': 'AUD',
      'JP': 'JPY',
      'CN': 'CNY',
    };
    return currencyMap[countryCode] ?? 'USD';
  }
}
