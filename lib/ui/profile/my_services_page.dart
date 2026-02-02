import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munokolive_music/models/service_model.dart';
import 'package:munokolive_music/providers/services_repository.dart';
import 'package:munokolive_music/ui/widgets/smart_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyServicesPage extends ConsumerStatefulWidget {
  const MyServicesPage({super.key});

  @override
  ConsumerState<MyServicesPage> createState() => _MyServicesPageState();
}

class _MyServicesPageState extends ConsumerState<MyServicesPage> {
  final _userId = Supabase.instance.client.auth.currentUser!.id;

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(providerServicesProvider(_userId));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Mes Services & Tarifs"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: servicesAsync.when(
        data: (services) {
          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.piano_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "Aucun service proposé",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Ajoutez vos compétences pour recevoir des offres",
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddServiceModal,
                    icon: const Icon(Icons.add),
                    label: const Text("Ajouter un Service"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Dismissible(
                key: Key(service.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Supprimer ?"),
                      content: const Text("Ce service ne sera plus visible."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Annuler"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            "Supprimer",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) {
                  ref
                      .read(servicesRepositoryProvider)
                      .deleteService(service.id);
                  ref.invalidate(providerServicesProvider(_userId));
                },
                child: Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.pinkAccent.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.work_outline,
                        color: Colors.pinkAccent,
                      ),
                    ),
                    title: Text(
                      service.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "${service.rateAmount.toStringAsFixed(0)} FCFA / ${service.rateType == 'hourly' ? 'heure' : 'prestation'}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Switch(
                      value: service.isActive,
                      onChanged: (val) async {
                        await ref
                            .read(servicesRepositoryProvider)
                            .updateService(service.copyWith(isActive: val));
                        ref.invalidate(providerServicesProvider(_userId));
                      },
                      thumbColor: WidgetStateProperty.all(Colors.pinkAccent),
                      trackColor:
                          WidgetStateProperty.all(Colors.pinkAccent.withValues(alpha: 0.4)),
                    ),
                    onTap: _showAddServiceModal,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            "Erreur: $err",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      floatingActionButton:
          servicesAsync.hasValue && servicesAsync.value!.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddServiceModal,
              backgroundColor: Colors.pinkAccent,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddServiceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _AddServiceForm(),
    ).then((_) {
      ref.invalidate(providerServicesProvider(_userId));
    });
  }
}

class _AddServiceForm extends ConsumerStatefulWidget {
  const _AddServiceForm();

  @override
  ConsumerState<_AddServiceForm> createState() => _AddServiceFormState();
}

class _AddServiceFormState extends ConsumerState<_AddServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  String _rateType = 'fixed';
  bool _isLoading = false;
  String _loadingStatus = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nouveau Service",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco("Titre (ex: Pianiste Jazz)"),
              validator: (v) => v!.isEmpty ? "Requis" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco("Description (Optionnel)"),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rateCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco("Tarif (FCFA)"),
                    validator: (v) => v!.isEmpty ? "Requis" : null,
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _rateType,
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                  underline: Container(),
                  items: const [
                    DropdownMenuItem(
                      value: 'fixed',
                      child: Text("/ Prestation"),
                    ),
                    DropdownMenuItem(value: 'hourly', child: Text("/ Heure")),
                  ],
                  onChanged: (v) => setState(() => _rateType = v!),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _loadingStatus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        "Ajouter le Service",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.grey[800],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _loadingStatus = 'Création du service...';
    });

    try {
      final service = ServiceModel(
        id: '', // Generated by DB
        providerId: '', // Set by repo
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        rateAmount: double.parse(_rateCtrl.text.trim()),
        rateType: _rateType,
        createdAt: DateTime.now(),
      );

      await ref.read(servicesRepositoryProvider).createService(service);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        SmartSnackBar.show(context, message: "Erreur: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
