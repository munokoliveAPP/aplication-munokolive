// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munokolive_music/models/service_model.dart';
import 'package:munokolive_music/providers/bookings_repository.dart';
import 'package:munokolive_music/providers/services_repository.dart';
import 'package:munokolive_music/ui/widgets/smart_snackbar.dart';

class BookingRequestPage extends ConsumerStatefulWidget {
  final String providerId;
  final String providerName;

  const BookingRequestPage({
    super.key,
    required this.providerId,
    required this.providerName,
  });

  @override
  ConsumerState<BookingRequestPage> createState() => _BookingRequestPageState();
}

class _BookingRequestPageState extends ConsumerState<BookingRequestPage> {
  ServiceModel? _selectedService;
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  final _locationCtrl = TextEditingController();
  bool _isLoading = false;
  String _loadingStatus = '';

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(
      providerServicesProvider(widget.providerId),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Réserver ${widget.providerName}"),
        backgroundColor: Colors.transparent,
      ),
      body: servicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            "Erreur: $err",
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (services) {
          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_busy, color: Colors.white54, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    "${widget.providerName} ne propose pas encore de services.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("1. Choisissez une prestation", style: _headerStyle),
                const SizedBox(height: 10),
                ...services.map((service) => _buildServiceCard(service)),

                const SizedBox(height: 24),
                const Text("2. Date et Heure", style: _headerStyle),
                const SizedBox(height: 10),
                _buildDatePicker(),

                const SizedBox(height: 24),
                const Text("3. Lieu de la mission", style: _headerStyle),
                const SizedBox(height: 10),
                TextField(
                  controller: _locationCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Ex: Église Philadelphie, Yopougon...",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.location_on,
                      color: Colors.pinkAccent,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                _buildTotalSection(),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading || _selectedService == null
                        ? null
                        : _submitBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      disabledBackgroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 24,
                                height: 24,
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            "CONFIRMER LA DEMANDE",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  Widget _buildServiceCard(ServiceModel service) {
    final isSelected = _selectedService?.id == service.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedService = service),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.pinkAccent.withValues(alpha: 0.2)
              : Colors.grey[900],
          border: Border.all(
            color: isSelected ? Colors.pinkAccent : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: service.id,
              groupValue: _selectedService?.id,
              onChanged: (_) => setState(() => _selectedService = service),
              activeColor: Colors.pinkAccent,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (service.description != null)
                    Text(
                      service.description!,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              "${service.rateAmount.toStringAsFixed(0)} F",
              style: const TextStyle(
                color: Colors.pinkAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white70),
                  const SizedBox(width: 10),
                  Text(
                    "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (time != null) setState(() => _selectedTime = time);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white70),
                  const SizedBox(width: 10),
                  Text(
                    _selectedTime.format(context),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSection() {
    if (_selectedService == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.pinkAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Total Estimé",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          Text(
            "${_selectedService!.rateAmount.toStringAsFixed(0)} FCFA",
            style: const TextStyle(
              color: Colors.pinkAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitBooking() async {
    if (_locationCtrl.text.isEmpty) {
      SmartSnackBar.show(
        context,
        message: "Veuillez indiquer un lieu",
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingStatus = 'Préparation de la demande...';
    });

    try {
      final finalDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      setState(() => _loadingStatus = 'Envoi de la réservation...');
      await ref
          .read(bookingsRepositoryProvider)
          .createBooking(
            providerId: widget.providerId,
            serviceId: _selectedService!.id,
            bookingDate: finalDate,
            locationName: _locationCtrl.text,
            totalPrice: _selectedService!.rateAmount,
          );

      if (mounted) {
        SmartSnackBar.show(context, message: "Demande envoyée avec succès !");
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SmartSnackBar.show(context, message: "Erreur: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
