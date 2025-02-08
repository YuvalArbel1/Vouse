import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_utils/nb_utils.dart'; // For AppTextField, boldTextStyle, etc.
import 'package:intl/intl.dart';         // For formatting the chosen date
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Our local user logic
import '../../../../domain/entities/user_entity.dart';
import '../../../core/resources/data_state.dart';
import '../../providers/home/local_user_providers.dart';
import '../home/home_screen.dart'; // Where we navigate after saving

import '../../../core/util/colors.dart';
import '../../../core/util/common.dart';

/// A screen allowing the user to edit personal information one time.
/// If they press "Continue," we store them in local DB and go to HomeScreen.
class EditProfileScreen extends ConsumerStatefulWidget {
  final bool isEditProfile;

  const EditProfileScreen({super.key, this.isEditProfile = false});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  /// Text controllers
  final TextEditingController fullNameController    = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();
  final TextEditingController connectXController    = TextEditingController(
    text: 'Tap to connect your X account',
  );

  /// Focus nodes
  final FocusNode fullNameFocusNode     = FocusNode();
  final FocusNode dateOfBirthFocusNode  = FocusNode();
  final FocusNode connectXFocusNode     = FocusNode();

  DateTime? selectedDOB;
  String? selectedGender;

  final List<String> genderOptions = [
    'Female',
    'Male',
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    setStatusBarColor(
      Colors.white,
      statusBarIconBrightness: Brightness.dark,
    );
  }

  @override
  void dispose() {
    setStatusBarColor(
      Colors.white,
      statusBarIconBrightness: Brightness.dark,
    );
    super.dispose();
  }

  /// Show a date picker for the user to choose a birth date
  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = DateTime(2000, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        selectedDOB = picked;
        dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  /// Placeholder for X (Twitter) connection
  void _connectToX() {
    toast("Connect to X tapped!");
  }

  /// Called when user taps "Continue." We'll save to local DB, then go Home.
  Future<void> _handleContinue() async {
    // If we are editing, maybe we do something else, but
    // presumably we always want to store or update the user.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      toast("No Firebase user found, cannot save local profile!");
      return;
    }

    final uid = user.uid;

    // Build our local user entity
    final entity = UserEntity(
      userId: uid,
      fullName: fullNameController.text.trim(),
      dateOfBirth: selectedDOB ?? DateTime(2000, 1, 1),
      gender: selectedGender ?? 'Prefer not to say',
      xCredential: null, // We'll store once we implement OAuth
    );

    // Save to local DB
    final saveResult = await ref
        .read(saveUserUseCaseProvider)
        .call(params: entity);

    if (saveResult is DataSuccess<void>) {
      // Navigate to HomeScreen
      if (widget.isEditProfile) {
        Navigator.pop(context); // if truly editing existing profile
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else if (saveResult is DataFailed<void>) {
      toast("Error saving user: ${saveResult.error?.error}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Edit Profile',
            style: boldTextStyle(color: Colors.black, size: 20),
          ),
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withAlpha(50),
              ),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          centerTitle: true,
          elevation: 0.0,
          systemOverlayStyle:
          const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
        ),
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/vouse_bg.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Stack(
              alignment: AlignmentDirectional.topCenter,
              children: [
                Positioned(
                  top: 80,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height - 80,
                    padding: const EdgeInsets.only(
                      top: 50,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    decoration: boxDecorationWithShadow(
                      backgroundColor: context.cardColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Personal Information',
                              style: boldTextStyle(size: 18)),
                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.withAlpha(50),
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Full Name',
                                    style: boldTextStyle(size: 14)),
                                const SizedBox(height: 8),
                                AppTextField(
                                  textFieldType: TextFieldType.NAME,
                                  decoration: waInputDecoration(
                                    hint: 'Enter your full name here',
                                  ),
                                  keyboardType: TextInputType.name,
                                  controller: fullNameController,
                                  focus: fullNameFocusNode,
                                ),
                                const SizedBox(height: 16),

                                Text('Date of Birth',
                                    style: boldTextStyle(size: 14)),
                                const SizedBox(height: 8),
                                // readOnly text field
                                AppTextField(
                                  textFieldType: TextFieldType.NAME,
                                  readOnly: true,
                                  controller: dateOfBirthController,
                                  focus: dateOfBirthFocusNode,
                                  keyboardType: TextInputType.text,
                                  decoration: waInputDecoration(
                                    hint: 'Tap to pick your birth date',
                                  ),
                                  onTap: _pickDateOfBirth,
                                ),
                                const SizedBox(height: 16),

                                Text('Gender', style: boldTextStyle()),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  decoration: waInputDecoration(
                                    hint: "Select your gender",
                                  ),
                                  items: genderOptions.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: secondaryTextStyle(),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedGender = value;
                                    });
                                  },
                                  value: selectedGender,
                                ),
                                const SizedBox(height: 16),

                                Text('Connect to X (Twitter)',
                                    style: boldTextStyle(size: 14)),
                                const SizedBox(height: 8),
                                // Another readOnly text field
                                Builder(
                                  builder: (ctx) {
                                    final baseDecoration = waInputDecoration(
                                      hint: 'Tap to connect your X account',
                                    );
                                    final updatedDecoration = baseDecoration.copyWith(
                                      filled: true,
                                      fillColor: vAccentColor.withAlpha(
                                        (0.06 * 255).toInt(),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.link,
                                        color: vAccentColor,
                                      ),
                                    );

                                    return AppTextField(
                                      textFieldType: TextFieldType.NAME,
                                      readOnly: true,
                                      controller: connectXController,
                                      focus: connectXFocusNode,
                                      keyboardType: TextInputType.text,
                                      decoration: updatedDecoration,
                                      onTap: _connectToX,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width * 0.1,
                              right: MediaQuery.of(context).size.width * 0.1,
                            ),
                            child: AppButton(
                              color: vPrimaryColor,
                              width: MediaQuery.of(context).size.width,
                              onTap: _handleContinue,
                              child: Text(
                                'Continue',
                                style: boldTextStyle(color: Colors.white),
                              ), // <--- Use the method
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 0,
                  child: Stack(
                    alignment: AlignmentDirectional.bottomEnd,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        height: 110,
                        width: 110,
                        decoration: const BoxDecoration(
                          color: vPrimaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: vAccentColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
