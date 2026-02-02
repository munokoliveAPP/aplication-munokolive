import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';

class AddMusicGroupPage extends StatefulWidget {
  const AddMusicGroupPage({super.key});

  @override
  State<AddMusicGroupPage> createState() => _AddMusicGroupPageState();
}

class _AddMusicGroupPageState extends State<AddMusicGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  final _logoUrlController = TextEditingController(); // Fallback

  File? _imageFile;
  bool _isLoading = false;
  final _supabase = Supabase.instance.client;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _logoUrlController.clear();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? logoUrl = _logoUrlController.text;

      // Upload image if selected
      if (_imageFile != null) {
        final fileName =
            'group_logos/${DateTime.now().millisecondsSinceEpoch}_${_imageFile!.path.split('/').last}';
        try {
          await _supabase.storage
              .from('app-assets')
              .upload(
                fileName,
                _imageFile!,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                ),
              );
          logoUrl = _supabase.storage.from('app-assets').getPublicUrl(fileName);
        } catch (e) {
          // Fallback if storage fails or bucket missing
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur upload image (utilisez une URL): $e'),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("Non authentifié");

      await _supabase.from('music_groups').insert({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'social_link': _linkController.text.trim(),
        'logo_url': logoUrl,
        'created_by': user.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Groupe ajouté avec succès !')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Dark theme
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Ajouter un Groupe"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker Area
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white24,
                      style: BorderStyle.solid,
                    ),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 50,
                              color: Colors.white54,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Toucher pour ajouter un logo",
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text("OU", style: TextStyle(color: Colors.white38)),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _logoUrlController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("URL du Logo (si pas d'image)"),
              ),
              const SizedBox(height: 20),

              // Fields
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Nom du Groupe"),
                validator: (value) => value!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: _inputDecoration("Description"),
                validator: (value) => value!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _linkController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Lien (Site Web / Facebook)"),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "PUBLIER LE GROUPE",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.deepPurpleAccent),
      ),
    );
  }
}
