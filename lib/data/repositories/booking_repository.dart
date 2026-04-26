
// ---------------------------------------------------------------------------
// booking_repository.dart
//
// Purpose: All booking lifecycle operations for SkillBridge.
//
// Responsibilities:
//   - Create bookings with availability checks
//   - Customer: view history, cancel pending bookings
//   - Provider: view incoming, accept/reject/complete
//   - Admin: view all bookings, flag disputes
//   - Real-time subscription to booking status changes
//
// Note: price_at_booking is snapshotted at creation time.
// Note: provider_id is denormalized for RLS performance.
//
// ---------------------------------------------------------------------------

import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;
import '../../core/errors/failures.dart';
import '../../services/supabase_service.dart';
import '../models/booking_model.dart';
import '../models/time_slot_model.dart';

class BookingRepository {
  BookingRepository._();
  static final BookingRepository instance = BookingRepository._();

  final _supabase = SupabaseService.instance;

  // Supabase join query — reused across multiple methods
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
      // Validate booking date is not in the past
      if (bookingDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        throw const ValidationFailure(
          'Booking date cannot be in the past.',
          field: 'booking_date',
        );
      }

      // Customer cannot book their own service
      if (customerId == providerId) {
        throw const PermissionFailure(
          'You cannot book your own service.',
        );
      }

      final data = await _supabase.from('bookings').insert({
        'service_id': serviceId,
        'customer_id': customerId,
        'provider_id': providerId,
        'booking_date': bookingDate.toIso8601String().split('T').first,
        'time_slot': timeSlot.value,
        'note': note,
        'status': 'pending',
        // Snapshot price at booking time — immutable after this
        'price_at_booking': servicePrice,
      }).select(_bookingJoinQuery).single();

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

  /// Gets all bookings for a customer, optionally filtered by status
  Future<List<BookingModel>> getCustomerBookings({
    required String customerId,
    BookingStatus? statusFilter,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      var query = _supabase.from('bookings')
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

  /// Gets a single booking by ID
  Future<BookingModel> getBookingById(String bookingId) async {
    try {
      final data = await _supabase.from('bookings')
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

  /// Customer cancels a pending booking
  Future<BookingModel> cancelBooking(String bookingId) async {
    try {
      // RLS policy already enforces status = pending check
      final data = await _supabase.from('bookings')
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

  /// Gets all bookings for a provider, optionally filtered by status
  Future<List<BookingModel>> getProviderBookings({
    required String providerId,
    BookingStatus? statusFilter,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      // Filters must come before .order/.range (PostgrestTransformBuilder has no .eq).
      var query = _supabase.from('bookings')
          .select(_bookingJoinQuery)
          .eq('provider_id', providerId);

      if (statusFilter != null) {
        query = query.eq('status', statusFilter.value);
      }

      final data = await query
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);
      return (data as List<dynamic>)
          .map((json) => BookingModel.fromJson(
              Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch provider bookings: $e');
    }
  }

  /// Provider accepts a booking
  Future<BookingModel> acceptBooking(String bookingId) async {
    try {
      final data = await _supabase.from('bookings')
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
  /// This maps SkillBridge's current coarse booking slots (morning/afternoon/evening)
  /// into displayable time slots for the new selector UI.
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

  /// Provider rejects a booking with optional reason
  Future<BookingModel> rejectBooking(
    String bookingId, {
    String? reason,
  }) async {
    try {
      final data = await _supabase.from('bookings')
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
      final data = await _supabase.from('bookings')
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
      final data = await _supabase.from('bookings')
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
