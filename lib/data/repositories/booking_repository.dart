// Booking repository for all booking lifecycle operations.
// This is the main data access layer for booking creation, booking history,
// provider actions, admin views, and slot availability checks.
//
// It also handles details users should not think about directly, such as
// snapshotting the booking price at creation time and shaping Supabase join
// results into app-friendly models.

import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;
import '../../core/errors/failures.dart';
import '../../services/supabase_service.dart';
import '../models/booking_model.dart';
import '../models/time_slot_model.dart';

class BookingRepository {
  BookingRepository._();
  static final BookingRepository instance = BookingRepository._();

  final _supabase = SupabaseService.instance;

  // Shared join query used by most booking lookups.
  // It pulls the booking plus linked service, customer, and provider data in
  // one query so the UI can render names and avatars without extra calls.
  static const String _bookingJoinQuery = '''
    *,
    services!service_id(title, image_urls),
    customer:users!customer_id(name, avatar_url),
    provider:users!provider_id(name, avatar_url)
  ''';

  // ── Create Booking ────────────────────────────────────────────────────────

  /// Creates a new booking request.
  ///
  /// Validates:
  ///   - Date is not in the past
  ///   - Customer is not booking their own service
  ///   - Snapshots the current service price
  Future<BookingModel> createBooking({
    required String serviceId,
    required String customerId,
    required String providerId,
    required DateTime bookingDate,
    required TimeSlot timeSlot,
    required double servicePrice,
    String? note,
  }) async {
    try {
      // Basic date guard so users cannot book a service for yesterday or older.
      if (bookingDate
          .isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        throw const ValidationFailure(
          'Booking date cannot be in the past.',
          field: 'booking_date',
        );
      }

      // A customer cannot book their own service listing.
      if (customerId == providerId) {
        throw const PermissionFailure(
          'You cannot book your own service.',
        );
      }

      final data = await _supabase
          .from('bookings')
          .insert({
            'service_id': serviceId,
            'customer_id': customerId,
            'provider_id': providerId,
            'booking_date': bookingDate.toIso8601String().split('T').first,
            'time_slot': timeSlot.value,
            'note': note,
            'status': 'pending',
            // Keep the price seen at booking time, even if the service changes later.
            'price_at_booking': servicePrice,
          })
          .select(_bookingJoinQuery)
          .single();

      return BookingModel.fromJson(Map<String, dynamic>.from(data));
    } on ValidationFailure {
      rethrow;
    } on PermissionFailure {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerFailure('Failed to create booking: ${e.message}');
    } catch (e) {
      throw ServerFailure('Failed to create booking: $e');
    }
  }

  // ── Customer Queries ──────────────────────────────────────────────────────

  /// Gets all bookings for a customer, optionally filtered by status.
  Future<List<BookingModel>> getCustomerBookings({
    required String customerId,
    BookingStatus? statusFilter,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      var query = _supabase
          .from('bookings')
          .select(_bookingJoinQuery)
          .eq('customer_id', customerId);

      if (statusFilter != null) {
        query = query.eq('status', statusFilter.value);
      }

      final data = await query
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);
      return (data as List<dynamic>)
          .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch bookings: $e');
    }
  }

  /// Gets one booking by ID with the linked service and user data.
  Future<BookingModel> getBookingById(String bookingId) async {
    try {
      final data = await _supabase
          .from('bookings')
          .select(_bookingJoinQuery)
          .eq('id', bookingId)
          .single();
      return BookingModel.fromJson(Map<String, dynamic>.from(data));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const NotFoundFailure('Booking not found.');
      }
      throw ServerFailure('Failed to fetch booking: ${e.message}');
    } catch (e) {
      throw ServerFailure('Failed to fetch booking: $e');
    }
  }

  /// Lets a customer cancel a pending booking.
  Future<BookingModel> cancelBooking(String bookingId) async {
    try {
      // The database policy still blocks invalid cancellations.
      final data = await _supabase
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId)
          .select(_bookingJoinQuery)
          .single();
      return BookingModel.fromJson(Map<String, dynamic>.from(data));
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw const PermissionFailure(
          'Only pending bookings can be cancelled.',
        );
      }
      throw ServerFailure('Failed to cancel booking: ${e.message}');
    } catch (e) {
      throw ServerFailure('Failed to cancel booking: $e');
    }
  }

  // ── Provider Operations ───────────────────────────────────────────────────

  /// Gets all bookings for a provider, optionally filtered by status.
  Future<List<BookingModel>> getProviderBookings({
    required String providerId,
    BookingStatus? statusFilter,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      // Build all filters before ordering and paging.
      var query = _supabase
          .from('bookings')
          .select(_bookingJoinQuery)
          .eq('provider_id', providerId);

      if (statusFilter != null) {
        query = query.eq('status', statusFilter.value);
      }

      final data = await query
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);
      return (data as List<dynamic>)
          .map((json) =>
              BookingModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch provider bookings: $e');
    }
  }

  /// Lets a provider confirm a booking request.
  Future<BookingModel> acceptBooking(String bookingId) async {
    try {
      final data = await _supabase
          .from('bookings')
          .update({'status': 'confirmed'})
          .eq('id', bookingId)
          .select(_bookingJoinQuery)
          .single();
      return BookingModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw ServerFailure('Failed to accept booking: $e');
    }
  }

  /// Returns available start times for a service on a given date.
  ///
  /// This maps SkillBridge's coarse booking slots (morning, afternoon, evening)
  /// into displayable time slots for the booking selector.
  Future<List<TimeSlotModel>> getAvailableSlots(
    String serviceId,
    DateTime date,
  ) async {
    try {
      final dateStr = date.toIso8601String().split('T').first;

      final data = await _supabase
          .from('bookings')
          .select('time_slot,status')
          .eq('service_id', serviceId)
          .eq('booking_date', dateStr)
          .inFilter('status', ['pending', 'confirmed']);

      final bookedSlots = (data as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['time_slot'] as String?)
          .whereType<String>()
          .toSet();

      final base = <({int hour, int minute, String key})>[
        (hour: 9, minute: 0, key: 'morning'),
        (hour: 14, minute: 0, key: 'afternoon'),
        (hour: 18, minute: 0, key: 'evening'),
      ];

      return base
          .map(
            (slot) => TimeSlotModel(
              startHour: slot.hour,
              startMinute: slot.minute,
              isAvailable: !bookedSlots.contains(slot.key),
            ),
          )
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch available slots: $e');
    }
  }

  /// Lets a provider reject a booking and optionally store a reason.
  Future<BookingModel> rejectBooking(
    String bookingId, {
    String? reason,
  }) async {
    try {
      final data = await _supabase
          .from('bookings')
          .update({
            'status': 'cancelled',
            'rejection_reason': reason,
          })
          .eq('id', bookingId)
          .select(_bookingJoinQuery)
          .single();
      return BookingModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw ServerFailure('Failed to reject booking: $e');
    }
  }

  /// Provider marks a booking as completed
  Future<BookingModel> completeBooking(String bookingId) async {
    try {
      final data = await _supabase
          .from('bookings')
          .update({'status': 'completed'})
          .eq('id', bookingId)
          .select(_bookingJoinQuery)
          .single();
      return BookingModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw ServerFailure('Failed to complete booking: $e');
    }
  }

  // ── Admin ─────────────────────────────────────────────────────────────────

  /// Admin: get all bookings across platform
  Future<List<BookingModel>> getAllBookings({
    BookingStatus? statusFilter,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      var query = _supabase.from('bookings').select(_bookingJoinQuery);

      if (statusFilter != null) {
        query = query.eq('status', statusFilter.value);
      }

      final data = await query
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);
      return (data as List<dynamic>)
          .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch all bookings: $e');
    }
  }

  /// Admin: flag a booking as disputed
  Future<BookingModel> flagAsDisputed(String bookingId) async {
    try {
      final data = await _supabase
          .from('bookings')
          .update({'status': 'disputed'})
          .eq('id', bookingId)
          .select(_bookingJoinQuery)
          .single();
      return BookingModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw ServerFailure('Failed to flag booking: $e');
    }
  }

  // ── Real-time ─────────────────────────────────────────────────────────────

  /// Stream of booking updates for a customer — drives real-time UI
  Stream<List<Map<String, dynamic>>> watchCustomerBookings(
    String customerId,
  ) {
    return _supabase.client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
  }

  /// Stream of incoming bookings for a provider — drives real-time UI
  Stream<List<Map<String, dynamic>>> watchProviderBookings(
    String providerId,
  ) {
    return _supabase.client
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('provider_id', providerId)
        .order('created_at', ascending: false);
  }
}
