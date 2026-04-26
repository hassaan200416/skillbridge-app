
// ---------------------------------------------------------------------------
// booking_provider.dart
//
// Purpose: Riverpod state management for bookings.
// Drives booking creation, status updates, and real-time tracking.
//
// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/time_slot_model.dart';
import '../../data/repositories/booking_repository.dart';
import '../../services/notification_service.dart';
import '../../core/errors/failures.dart';

// ── Customer Booking Providers ────────────────────────────────────────────

/// All bookings for a customer
final customerBookingsProvider =
    FutureProvider.family<List<BookingModel>, String>((ref, customerId) {
  return BookingRepository.instance.getCustomerBookings(
    customerId: customerId,
  );
});

/// Customer bookings filtered by status
final customerBookingsByStatusProvider =
    FutureProvider.family<List<BookingModel>, ({String customerId, BookingStatus status})>(
        (ref, args) {
  return BookingRepository.instance.getCustomerBookings(
    customerId: args.customerId,
    statusFilter: args.status,
  );
});

// ── Provider Booking Providers ────────────────────────────────────────────

/// All bookings for a provider
final providerBookingsProvider =
    FutureProvider.family<List<BookingModel>, String>((ref, providerId) {
  return BookingRepository.instance.getProviderBookings(
    providerId: providerId,
  );
});

/// Provider bookings filtered by status
final providerBookingsByStatusProvider =
    FutureProvider.family<List<BookingModel>, ({String providerId, BookingStatus status})>(
        (ref, args) {
  return BookingRepository.instance.getProviderBookings(
    providerId: args.providerId,
    statusFilter: args.status,
  );
});

class AvailableSlotsParams {
  const AvailableSlotsParams({
    required this.serviceId,
    required this.date,
  });

  final String serviceId;
  final DateTime date;
}

final availableSlotsProvider = FutureProvider.family<List<TimeSlotModel>,
    AvailableSlotsParams>((ref, params) {
  return BookingRepository.instance.getAvailableSlots(
    params.serviceId,
    params.date,
  );
});

// ── Single Booking ────────────────────────────────────────────────────────

final bookingDetailProvider =
    FutureProvider.family<BookingModel, String>((ref, bookingId) {
  return BookingRepository.instance.getBookingById(bookingId);
});

// ── Real-time Streams ─────────────────────────────────────────────────────

/// Real-time stream of customer bookings — drives live status updates
final customerBookingsStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>(
        (ref, customerId) {
  return BookingRepository.instance.watchCustomerBookings(customerId);
});

/// Real-time stream of provider bookings — drives incoming booking alerts
final providerBookingsStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>(
        (ref, providerId) {
  return BookingRepository.instance.watchProviderBookings(providerId);
});

/// Admin: all platform bookings
final getAllBookingsProvider = FutureProvider<List<BookingModel>>((ref) {
  return BookingRepository.instance.getAllBookings(pageSize: 100);
});

// ── Booking Actions ───────────────────────────────────────────────────────

class BookingActionState {
  final bool isLoading;
  final Failure? error;
  final BookingModel? result;
  final bool isSuccess;

  const BookingActionState({
    this.isLoading = false,
    this.error,
    this.result,
    this.isSuccess = false,
  });

  BookingActionState copyWith({
    bool? isLoading,
    Failure? error,
    BookingModel? result,
    bool? isSuccess,
  }) {
    return BookingActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      result: result ?? this.result,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class BookingActionNotifier extends StateNotifier<BookingActionState> {
  BookingActionNotifier(this._ref) : super(const BookingActionState());

  final Ref _ref;
  final _repo = BookingRepository.instance;
  final _notifications = NotificationService.instance;

  Future<bool> createBooking({
    required String serviceId,
    required String customerId,
    required String providerId,
    required DateTime bookingDate,
    required TimeSlot timeSlot,
    required double servicePrice,
    required String serviceName,
    String? note,
  }) async {
    state = const BookingActionState(isLoading: true);
    try {
      final booking = await _repo.createBooking(
        serviceId: serviceId,
        customerId: customerId,
        providerId: providerId,
        bookingDate: bookingDate,
        timeSlot: timeSlot,
        servicePrice: servicePrice,
        note: note,
      );
      // Notify provider
      await _notifications.onBookingCreated(
        providerId: providerId,
        bookingId: booking.id,
        serviceName: serviceName,
      );
      _ref.invalidate(customerBookingsProvider(customerId));
      state = BookingActionState(isSuccess: true, result: booking);
      return true;
    } on Failure catch (f) {
      state = BookingActionState(error: f);
      return false;
    } catch (e) {
      state = BookingActionState(error: ServerFailure(e.toString()));
      return false;
    }
  }

  Future<bool> cancelBooking({
    required String bookingId,
    required String customerId,
    required String providerId,
    required String serviceName,
  }) async {
    state = const BookingActionState(isLoading: true);
    try {
      final booking = await _repo.cancelBooking(bookingId);
      await _notifications.onBookingCancelled(
        recipientId: providerId,
        bookingId: bookingId,
        serviceName: serviceName,
      );
      _ref.invalidate(customerBookingsProvider(customerId));
      _ref.invalidate(bookingDetailProvider(bookingId));
      state = BookingActionState(isSuccess: true, result: booking);
      return true;
    } on Failure catch (f) {
      state = BookingActionState(error: f);
      return false;
    } catch (e) {
      state = BookingActionState(error: ServerFailure(e.toString()));
      return false;
    }
  }

  Future<bool> acceptBooking({
    required String bookingId,
    required String customerId,
    required String providerId,
    required String serviceName,
  }) async {
    state = const BookingActionState(isLoading: true);
    try {
      final booking = await _repo.acceptBooking(bookingId);
      await _notifications.onBookingConfirmed(
        customerId: customerId,
        bookingId: bookingId,
        serviceName: serviceName,
      );
      _ref.invalidate(providerBookingsProvider(providerId));
      _ref.invalidate(bookingDetailProvider(bookingId));
      state = BookingActionState(isSuccess: true, result: booking);
      return true;
    } on Failure catch (f) {
      state = BookingActionState(error: f);
      return false;
    } catch (e) {
      state = BookingActionState(error: ServerFailure(e.toString()));
      return false;
    }
  }

  Future<bool> rejectBooking({
    required String bookingId,
    required String customerId,
    required String providerId,
    required String serviceName,
    String? reason,
  }) async {
    state = const BookingActionState(isLoading: true);
    try {
      final booking = await _repo.rejectBooking(bookingId, reason: reason);
      await _notifications.onBookingRejected(
        customerId: customerId,
        bookingId: bookingId,
        serviceName: serviceName,
      );
      _ref.invalidate(providerBookingsProvider(providerId));
      _ref.invalidate(bookingDetailProvider(bookingId));
      state = BookingActionState(isSuccess: true, result: booking);
      return true;
    } on Failure catch (f) {
      state = BookingActionState(error: f);
      return false;
    } catch (e) {
      state = BookingActionState(error: ServerFailure(e.toString()));
      return false;
    }
  }

  Future<bool> completeBooking({
    required String bookingId,
    required String customerId,
    required String providerId,
    required String serviceName,
  }) async {
    state = const BookingActionState(isLoading: true);
    try {
      final booking = await _repo.completeBooking(bookingId);
      await _notifications.onBookingCompleted(
        customerId: customerId,
        bookingId: bookingId,
        serviceName: serviceName,
      );
      _ref.invalidate(providerBookingsProvider(providerId));
      _ref.invalidate(bookingDetailProvider(bookingId));
      state = BookingActionState(isSuccess: true, result: booking);
      return true;
    } on Failure catch (f) {
      state = BookingActionState(error: f);
      return false;
    } catch (e) {
      state = BookingActionState(error: ServerFailure(e.toString()));
      return false;
    }
  }

  void clearState() => state = const BookingActionState();
}

final bookingActionProvider =
    StateNotifierProvider<BookingActionNotifier, BookingActionState>((ref) {
  return BookingActionNotifier(ref);
});
