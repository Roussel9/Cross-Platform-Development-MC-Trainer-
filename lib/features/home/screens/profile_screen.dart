import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mc_trainer_kami/core/constants/app_colors.dart';
import 'package:mc_trainer_kami/core/theme/app_theme.dart';
import 'package:mc_trainer_kami/provider/backend_provider.dart';
import 'package:flutter/foundation.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BackendProvider>().fetchAvatarUrl();
    });
  }

  void _initializeControllers() {
    final backend = context.read<BackendProvider>();

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

  void _toggleEditMode() => setState(() => _isEditing = !_isEditing);

  void _cancelEditing() {
    _initializeControllers();
    setState(() => _isEditing = false);
  }

  Future<void> _saveChanges() async {
    // TODO: Implementiere updateUserData im Provider
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Änderungen gespeichert'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
        ),
        body: Consumer<BackendProvider>(
          builder: (context, backend, _) {
            // Falls der Provider gerade lädt (z.B. beim Upload)
            if (backend.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

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
    // Entscheiden, welches Bild angezeigt wird:
    // 1. Priorität: Das gerade lokal ausgewählte File (noch im Upload)
    // 2. Priorität: Die URL aus Supabase
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
                Text(
                  backend.email,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 1,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... (Restliche Hilfsmethoden bleiben identisch wie in deiner Vorlage)

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
              ),
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
                  Text(
                    'Persönliche Informationen',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColorDark,
                    ),
                  ),
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
              const SizedBox(height: 8),

              _buildPersonalInfoField(
                label: 'Vorname *',
                controller: _firstNameController,
                isEditing: _isEditing,
                isSmallScreen: isSmallScreen,
              ),
              _buildPersonalInfoField(
                label: 'Nachname *',
                controller: _lastNameController,
                isEditing: _isEditing,
                isSmallScreen: isSmallScreen,
              ),
              _buildPersonalInfoField(
                label: 'E-Mail *',
                controller: _emailController,
                isEditing: _isEditing,
                keyboardType: TextInputType.emailAddress,
                isSmallScreen: isSmallScreen,
              ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          if (isEditing)
            // BEARBEITUNGS-MODUS: Eingabefeld mit Rahmen
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryColorLight.withOpacity(0.5),
                ),
              ),
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            )
          else
            // LESE-MODUS: Nur Text, dezent unterstrichen oder einfach schlicht
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                controller.text.isNotEmpty
                    ? controller.text
                    : 'Nicht angegeben',
                style: TextStyle(
                  fontSize: isSmallScreen ? 15 : 17,
                  fontWeight: FontWeight.w500,
                  color: controller.text.isNotEmpty
                      ? Colors.black87
                      : Colors.grey[400],
                ),
              ),
            ),
          if (!isEditing) const Divider(height: 16, thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _cancelEditing,
              child: const Text('Abbrechen'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _saveChanges,
              child: const Text('Speichern'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {}, // Hier deine Logout Logik
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text('Abmelden', style: TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
