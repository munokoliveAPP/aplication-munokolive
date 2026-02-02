import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munokolive_music/models/booking_model.dart';
import 'package:munokolive_music/providers/bookings_repository.dart';
import 'package:munokolive_music/ui/widgets/smart_snackbar.dart';

class BookingsListPage extends ConsumerStatefulWidget {
  const BookingsListPage({super.key});

  @override
  ConsumerState<BookingsListPage> createState() => _BookingsListPageState();
}

class _BookingsListPageState extends ConsumerState<BookingsListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Mes Réservations"),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.pinkAccent,
          tabs: const [
            Tab(text: "Mes Commandes"),
            Tab(text: "Mes Missions"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_ClientBookingsList(), _ProviderBookingsList()],
      ),
    );
  }
}

class _ClientBookingsList extends ConsumerWidget {
  const _ClientBookingsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(clientBookingsStreamProvider);

    return bookingsAsync.when(
      data: (bookings) => _buildList(context, bookings, isClient: true),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text(
          "Erreur: $err",
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _ProviderBookingsList extends ConsumerWidget {
  const _ProviderBookingsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(providerBookingsStreamProvider);

    return bookingsAsync.when(
      data: (bookings) =>
          _buildList(context, bookings, isClient: false, ref: ref),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text(
          "Erreur: $err",
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

Widget _buildList(
  BuildContext context,
  List<BookingModel> bookings, {
  required bool isClient,
  WidgetRef? ref,
}) {
  if (bookings.isEmpty) {
    return Center(
      child: Text(
        isClient ? "Aucune commande en cours" : "Aucune mission reçue",
        style: const TextStyle(color: Colors.white54),
      ),
    );
  }

  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: bookings.length,
    itemBuilder: (context, index) {
      final booking = bookings[index];
      return _BookingCard(booking: booking, isClient: isClient, ref: ref);
    },
  );
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isClient;
  final WidgetRef? ref;

  const _BookingCard({required this.booking, required this.isClient, this.ref});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);
    final statusText = _getStatusText(booking.status);

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  "${booking.totalPrice?.toStringAsFixed(0) ?? '?'} FCFA",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  "${booking.bookingDate.day}/${booking.bookingDate.month} à ${booking.bookingDate.hour}h${booking.bookingDate.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.locationName ?? "Lieu non précisé",
                    style: const TextStyle(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isClient &&
                booking.status == BookingStatus.pending &&
                ref != null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(
                        context,
                        booking.id,
                        BookingStatus.declined,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text("REFUSER"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(
                        context,
                        booking.id,
                        BookingStatus.accepted,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("ACCEPTER"),
                    ),
                  ),
                ],
              ),
            if (!isClient &&
                booking.status == BookingStatus.accepted &&
                ref != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _updateStatus(context, booking.id, BookingStatus.enRoute),
                  icon: const Icon(Icons.directions_car),
                  label: const Text("JE SUIS EN ROUTE"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ),
            if (!isClient &&
                booking.status == BookingStatus.enRoute &&
                ref != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus(
                    context,
                    booking.id,
                    BookingStatus.inProgress,
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("COMMENCER LA MISSION"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ),
            if (!isClient &&
                booking.status == BookingStatus.inProgress &&
                ref != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus(
                    context,
                    booking.id,
                    BookingStatus.completed,
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text("TERMINER LA MISSION"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    String id,
    BookingStatus status,
  ) async {
    try {
      await ref!.read(bookingsRepositoryProvider).updateStatus(id, status);
      if (context.mounted) {
        SmartSnackBar.show(context, message: "Statut mis à jour !");
      }
    } catch (e) {
      if (context.mounted) {
        SmartSnackBar.show(context, message: "Erreur: $e", isError: true);
      }
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.accepted:
        return Colors.green;
      case BookingStatus.declined:
        return Colors.red;
      case BookingStatus.enRoute:
        return Colors.blue;
      case BookingStatus.inProgress:
        return Colors.purple;
      case BookingStatus.completed:
        return Colors.teal;
      case BookingStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return "EN ATTENTE";
      case BookingStatus.accepted:
        return "ACCEPTÉE";
      case BookingStatus.declined:
        return "REFUSÉE";
      case BookingStatus.enRoute:
        return "EN ROUTE";
      case BookingStatus.inProgress:
        return "EN COURS";
      case BookingStatus.completed:
        return "TERMINÉE";
      case BookingStatus.cancelled:
        return "ANNULÉE";
    }
  }
}
