import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mc_trainer_kami/core/constants/app_colors.dart';
import 'package:mc_trainer_kami/core/theme/app_theme.dart';
import 'package:mc_trainer_kami/provider/backend_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _birthDateController;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final backend = context.read<BackendProvider>();

    // Namen aus Backend splitten
    final nameParts = backend.fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : 'User';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _emailController = TextEditingController(text: backend.email);
    _birthDateController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _cancelEditing() {
    _initializeControllers();
    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _saveChanges() async {
    // TODO: Hier Änderungen in Supabase speichern
    setState(() {
      _isEditing = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Änderungen gespeichert'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Abmelden'),
          content: const Text('Möchten Sie sich wirklich abmelden?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Abbrechen',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Abmelden'),
            ),
          ],
        );
      },
    );
  }

  void _performLogout() {
    // TODO: Authentifizierung mit Backend abmelden
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Erfolgreich abgemeldet'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _selectProfileImage() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Profilbild auswählen'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: const ListTile(
                    leading: Icon(Icons.photo_library),
                    title: Text('Aus Galerie auswählen'),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                ),
                GestureDetector(
                  child: const ListTile(
                    leading: Icon(Icons.camera_alt),
                    title: Text('Foto aufnehmen'),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        final backend = context.read<BackendProvider>();
        backend.selectedImageFile = File(pickedFile.path);
        setState(() {});

        await backend.setPicture();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profilbild hochgeladen'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        final backend = context.read<BackendProvider>();
        backend.selectedImageFile = File(pickedFile.path);
        setState(() {});

        await backend.setPicture();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto hochgeladen'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteProfileImage() async {
    final backend = context.read<BackendProvider>();
    await backend.deletePicture();
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profilbild gelöscht'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'Profil',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primaryColorDark,
          iconTheme: IconThemeData(color: AppColors.primaryColorDark),
        ),
        body: Consumer<BackendProvider>(
          builder: (context, backend, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12.0 : 16.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileHeader(backend, isSmallScreen),
                            SizedBox(height: isSmallScreen ? 16 : 24),
                            _buildLearningStatsSection(backend, isSmallScreen),
                            SizedBox(height: isSmallScreen ? 16 : 24),
                            _buildPersonalInfoSection(isSmallScreen),
                            SizedBox(height: isSmallScreen ? 24 : 32),
                            if (_isEditing) _buildActionButtons(isSmallScreen),
                            _buildLogoutButton(isSmallScreen),
                            const Spacer(),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).padding.bottom + 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BackendProvider backend, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: AppColors.appHeaderBackgroundGradient,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _selectProfileImage,
            child: Stack(
              children: [
                Container(
                  width: isSmallScreen ? 60 : 80,
                  height: isSmallScreen ? 60 : 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(
                      color: Colors.white,
                      width: isSmallScreen ? 2 : 3,
                    ),
                    image: backend.selectedImageFile != null
                        ? DecorationImage(
                            image: FileImage(backend.selectedImageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: backend.selectedImageFile == null
                      ? Icon(
                          Icons.person,
                          size: isSmallScreen ? 30 : 40,
                          color: Colors.white,
                        )
                      : null,
                ),
                // Edit Button
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColorLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: isSmallScreen ? 1.5 : 2,
                      ),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: isSmallScreen ? 14 : 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Delete Button
                if (backend.selectedImageFile != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _deleteProfileImage,
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Icon(
                          Icons.close,
                          size: isSmallScreen ? 12 : 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  backend.fullName.isNotEmpty
                      ? backend.fullName
                      : backend.userName,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  backend.email,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmallScreen ? 4 : 8),
                Text(
                  'Initialen: ${backend.userInitials}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 16),
                Row(
                  children: [
                    _buildCounterItem(
                      count: backend.questionsThisWeek.toString(),
                      label: 'Fragen',
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 20),
                    _buildCounterItem(
                      count: backend.modulesCompleted.toString(),
                      label: 'Module',
                      isSmallScreen: isSmallScreen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterItem({
    required String count,
    required String label,
    required bool isSmallScreen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildLearningStatsSection(
    BackendProvider backend,
    bool isSmallScreen,
  ) {
    final progress = backend.calculateProgress(backend.lastSession);
    final progressPercentage = (progress * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: isSmallScreen ? 4.0 : 8.0,
            bottom: isSmallScreen ? 8 : 12,
          ),
          child: Text(
            'Lernstatistiken',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColorDark,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildStatRow(
                icon: Icons.timer_outlined,
                label: 'Fragen diese Woche',
                value: backend.questionsThisWeek.toString(),
                valueColor: Colors.green,
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              _buildStatRow(
                icon: Icons.bar_chart_outlined,
                label: 'Fortschritt',
                value: '$progressPercentage%',
                valueColor: AppColors.primaryColorLight,
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              _buildStatRow(
                icon: Icons.local_fire_department,
                label: 'Aktuelle Serie',
                value: '${backend.currentStreak} Tage',
                valueColor: Colors.orange,
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    required bool isSmallScreen,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
          decoration: BoxDecoration(
            color: valueColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
          ),
          child: Icon(icon, color: valueColor, size: isSmallScreen ? 20 : 24),
        ),
        SizedBox(width: isSmallScreen ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: isSmallScreen ? 4.0 : 8.0,
            bottom: isSmallScreen ? 8 : 12,
          ),
          child: Text(
            'Persönlich',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColorDark,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Persönliche Informationen',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColorDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  TextButton.icon(
                    onPressed: _toggleEditMode,
                    icon: Icon(
                      _isEditing ? Icons.close : Icons.edit,
                      size: isSmallScreen ? 14 : 18,
                      color: AppColors.primaryColorLight,
                    ),
                    label: Text(
                      _isEditing ? 'Abbrechen' : 'Bearbeiten',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: AppColors.primaryColorLight,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(thickness: 1),
              SizedBox(height: isSmallScreen ? 12 : 16),
              _buildPersonalInfoField(
                label: 'Vorname *',
                controller: _firstNameController,
                isEditing: _isEditing,
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              _buildPersonalInfoField(
                label: 'Nachname *',
                controller: _lastNameController,
                isEditing: _isEditing,
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              _buildPersonalInfoField(
                label: 'E-Mail *',
                controller: _emailController,
                isEditing: _isEditing,
                keyboardType: TextInputType.emailAddress,
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              _buildPersonalInfoField(
                label: 'Geburtsdatum',
                controller: _birthDateController,
                isEditing: _isEditing,
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required bool isSmallScreen,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: isSmallScreen ? 4 : 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 8 : 0,
          ),
          decoration: BoxDecoration(
            color: isEditing ? Colors.white : Colors.grey[50],
            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
            border: Border.all(
              color: isEditing
                  ? AppColors.primaryColorLight
                  : const Color(0xFFE0E0E0),
            ),
          ),
          child: isEditing
              ? TextFormField(
                  controller: controller,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 10 : 12,
                    ),
                  ),
                  keyboardType: keyboardType,
                )
              : Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 10 : 12,
                  ),
                  child: Text(
                    controller.text,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isSmallScreen) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _cancelEditing,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primaryColorLight),
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
              ),
            ),
            child: Text(
              'Abbrechen',
              style: TextStyle(
                color: AppColors.primaryColorLight,
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: isSmallScreen ? 12 : 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColorLight,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
              ),
              elevation: 2,
            ),
            child: Text(
              'Speichern',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(
        top: isSmallScreen ? 16 : 24,
        bottom: isSmallScreen ? 8 : 16,
      ),
      child: OutlinedButton.icon(
        onPressed: _showLogoutDialog,
        icon: Icon(
          Icons.logout,
          size: isSmallScreen ? 18 : 22,
          color: Colors.red,
        ),
        label: Text(
          'Abmelden',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 14 : 18,
            horizontal: isSmallScreen ? 16 : 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 14),
          ),
          backgroundColor: Colors.red.withOpacity(0.05),
        ),
      ),
    );
  }
}
