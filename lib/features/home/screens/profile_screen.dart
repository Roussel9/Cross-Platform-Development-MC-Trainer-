import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:mc_trainer_kami/core/constants/app_colors.dart';
import 'package:mc_trainer_kami/core/theme/app_theme.dart';
import 'package:mc_trainer_kami/provider/backend_provider.dart';
import 'package:mc_trainer_kami/features/auth/services/auth_service.dart';
import 'package:mc_trainer_kami/provider/backend_provider.dart';
import 'package:flutter/foundation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;

  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _usernameController = TextEditingController();

    // Profil Daten laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BackendProvider>().fetchAvatarUrl();
    });
  }

  void _loadProfileData() {
    final provider = context.read<BackendProvider>();
    provider.fetchProfileData();
  }

  void _updateControllersFromProvider(BackendProvider provider) {
    _nameController.text = provider.profileName;
    _emailController.text = provider.profileEmail;
    _usernameController.text = provider.profileUsername;
  }

  void _toggleEditMode() {
    if (!_isEditing) {
      final provider = context.read<BackendProvider>();
      _updateControllersFromProvider(provider);
    }

    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      final provider = context.read<BackendProvider>();
      _updateControllersFromProvider(provider);
    });
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte füllen Sie alle Pflichtfelder aus (*)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final provider = context.read<BackendProvider>();

    // Prüfe ob Email geändert wurde
    final emailChanged = _emailController.text != provider.profileEmail;

    final success = await provider.updateProfile(
      name: _nameController.text,
      email: _emailController.text,
      username: _usernameController.text,
    );

    setState(() {
      _isSaving = false;
      _isEditing = false;
    });

    if (success) {
      if (emailChanged) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email wurde SOFORT geändert auf: ${_emailController.text}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Änderungen gespeichert'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Speichern'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Abmelde-Funktion mit Bestätigungsdialog
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
                Navigator.of(context).pop(); // Dialog schließen
              },
              child: const Text(
                'Abbrechen',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog schließen
                _performLogout(); // Abmeldung durchführen
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

  // Eigentliche Abmelde-Logik
  void _performLogout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Erfolgreich abgemeldet'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Navigiere direkt zur Login-Seite mit dem Route-Namen
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
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
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Aus Galerie auswählen'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Foto aufnehmen'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        final backend = context.read<BackendProvider>();

        if (kIsWeb) {
          // Für WEB: Wir lesen die Bytes aus dem XFile
          final Uint8List imageBytes = await pickedFile.readAsBytes();
          await backend.uploadAvatar(imageBytes);
        } else {
          // Für MOBILE: Wir übergeben das File Objekt
          await backend.uploadAvatar(File(pickedFile.path));
        }

        if (mounted && backend.error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profilbild aktualisiert'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (backend.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(backend.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Picker Error: $e");
    }
  }

  Future<void> _deleteProfileImage() async {
    final backend = context.read<BackendProvider>();
    await backend.deletePicture();
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
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BackendProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !_isEditing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!_isEditing) {
          _updateControllersFromProvider(provider);
        }

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
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12.0 : 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(provider, isSmallScreen),
                  SizedBox(height: isSmallScreen ? 16 : 24),

                  _buildLearningStatsSection(provider, isSmallScreen),
                  SizedBox(height: isSmallScreen ? 16 : 24),

                  _buildPersonalInfoSection(provider, isSmallScreen),
                  SizedBox(height: isSmallScreen ? 24 : 32),

                  if (_isEditing) _buildActionButtons(isSmallScreen),

                  _buildLogoutButton(isSmallScreen),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BackendProvider provider, bool isSmallScreen) {
    // Entscheiden, welches Bild angezeigt wird:
    // 1. Priorität: Das gerade lokal ausgewählte File (noch im Upload)
    // 2. Priorität: Die URL aus Supabase
    BackendProvider backend = provider;
    ImageProvider? imageProvider;
    if (backend.selectedImageFile != null) {
      imageProvider = FileImage(backend.selectedImageFile!);
    } else if (backend.avatarUrl != null) {
      imageProvider = NetworkImage(backend.avatarUrl!);
    }
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
          // Profilbild mit Bearbeitungs-Icon (STIFT HINZUFÜGEN)
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
                    image: imageProvider != null
                        ? DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageProvider == null
                      ? Icon(
                          Icons.person,
                          size: isSmallScreen ? 30 : 40,
                          color: Colors.white,
                        )
                      : null,
                ),
                // Stift-Icon hinzufügen
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
                // Delete Button erscheint nur, wenn ein Bild existiert
                if (backend.avatarUrl != null ||
                    backend.selectedImageFile != null)
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

          // Profilinformationen
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  provider.profileName.isNotEmpty
                      ? provider.profileName
                      : 'Nutzer',
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
                  provider.profileEmail,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Mitglied seit Datum
                SizedBox(height: isSmallScreen ? 4 : 8),
                Text(
                  provider.profileCreatedAt.isNotEmpty
                      ? provider.profileCreatedAt
                      : 'Mitglied seit heute',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),

                if (provider.profileUsername.isNotEmpty) ...[
                  SizedBox(height: isSmallScreen ? 4 : 8),
                  Text(
                    '@${provider.profileUsername}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],

                SizedBox(height: isSmallScreen ? 8 : 16),
                Row(
                  children: [
                    _buildCounterItem(
                      count: provider.totalQuestions.toString(),
                      label: 'Fragen',
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 20),
                    _buildCounterItem(
                      count: provider.modulesCompleted.toString(),
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
    BackendProvider provider,
    bool isSmallScreen,
  ) {
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
              // Gelernte Stunden
              _buildStatRow(
                icon: Icons.timer_outlined,
                label: 'Gelernte Stunden',
                value: '${provider.learnedHours}h',
                valueColor: Colors.green,
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),

              _buildStatRow(
                icon: Icons.bar_chart_outlined,
                label: 'Durchschnittliche Punktzahl',
                value: '${provider.averageScore.toStringAsFixed(1)}%',
                valueColor: AppColors.primaryColorLight,
                isSmallScreen: isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),

              _buildStatRow(
                icon: Icons.check_circle_outline,
                label: 'Module abgeschlossen',
                value: '${provider.modulesCompleted}/12',
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

  Widget _buildPersonalInfoSection(
    BackendProvider provider,
    bool isSmallScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: isSmallScreen ? 4.0 : 8.0,
            bottom: isSmallScreen ? 8 : 12,
          ),
          child: Text(
            'Persönliche Informationen',
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
                      color: _isEditing
                          ? Colors.grey
                          : AppColors.primaryColorLight,
                    ),
                    label: Text(
                      _isEditing ? 'Abbrechen' : 'Bearbeiten',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: _isEditing
                            ? Colors.grey
                            : AppColors.primaryColorLight,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(thickness: 1),
              SizedBox(height: isSmallScreen ? 12 : 16),

              _buildPersonalInfoField(
                label: 'Name *',
                controller: _nameController,
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
                label: 'Username',
                controller: _usernameController,
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
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: isEditing ? Colors.white : Colors.grey[50],
            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
            border: Border.all(
              color: isEditing
                  ? AppColors.primaryColorLight
                  : const Color(0xFFE0E0E0),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: isEditing
                    ? TextFormField(
                        controller: controller,
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
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
                          controller.text.isNotEmpty
                              ? controller.text
                              : 'Nicht gesetzt',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: controller.text.isNotEmpty
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ),
              ),
            ],
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
