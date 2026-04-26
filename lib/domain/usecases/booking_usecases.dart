
// booking_usecases.dart
//
// Purpose: Domain-layer use-cases for booking operations.
// Responsibilities:
//   - Validate scheduling rules (e.g. cannot book in the past).
//   - Guard status transitions (only provider can confirm; only pending can be cancelled).
//   - Delegate data access to [BookingRepository].
//   - Return typed results — never throw.
// Dependencies:
//   - data/repositories/booking_repository.dart
//   - data/models/booking_model.dart
//   - core/errors/failures.dart

import '../../core/errors/failures.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/booking_repository.dart';

class CreateBookingUseCase {
  const CreateBookingUseCase();

  Future<(BookingModel?, Failure?)> call(BookingModel booking) async {
    if (booking.bookingDate.isBefore(DateTime.now())) {
      return (
        null,
        const ValidationFailure(
          'Booking date must be in the future.',
          field: 'bookingDate',
        ),
      );
    }
    try {
      final created = await BookingRepository.instance.createBooking(
        serviceId: booking.serviceId,
        customerId: booking.customerId,
        providerId: booking.providerId,
        bookingDate: booking.bookingDate,
        timeSlot: booking.timeSlot,
        servicePrice: booking.priceAtBooking,
        note: booking.note,
      );
      return (created, null);
    } on Failure catch (e) {
      return (null, e);
    }
  }
}

class GetBookingByIdUseCase {
  const GetBookingByIdUseCase();

  Future<(BookingModel?, Failure?)> call(String id) async {
    try {
      final booking = await BookingRepository.instance.getBookingById(id);
      return (booking, null);
    } on Failure catch (e) {
      return (null, e);
    }
  }
}

class GetCustomerBookingsUseCase {
  const GetCustomerBookingsUseCase();

  Future<(List<BookingModel>, Failure?)> call(String customerId) async {
    try {
      final list = await BookingRepository.instance.getCustomerBookings(
        customerId: customerId,
      );
      return (list, null);
    } on Failure catch (e) {
      return (<BookingModel>[], e);
    }
  }
}

class GetProviderBookingsUseCase {
  const GetProviderBookingsUseCase();

  Future<(List<BookingModel>, Failure?)> call(String providerId) async {
    try {
      final list = await BookingRepository.instance.getProviderBookings(
        providerId: providerId,
      );
      return (list, null);
    } on Failure catch (e) {
      return (<BookingModel>[], e);
    }
  }
}

class UpdateBookingStatusUseCase {
  const UpdateBookingStatusUseCase();

  /// Maps [status] to provider/admin actions. For customer cancellation use [CancelBookingUseCase].
  Future<(BookingModel?, Failure?)> call(String id, String status) async {
    try {
      final normalized = status.toLowerCase();
      switch (normalized) {
        case 'confirmed':
          final booking = await BookingRepository.instance.acceptBooking(id);
          return (booking, null);
        case 'completed':
          final booking = await BookingRepository.instance.completeBooking(id);
          return (booking, null);
        case 'cancelled':
          final booking = await BookingRepository.instance.rejectBooking(id);
          return (booking, null);
        case 'disputed':
          final booking = await BookingRepository.instance.flagAsDisputed(id);
          return (booking, null);
        default:
          return (
            null,
            ServerFailure('Unsupported status transition: $status'),
          );
      }
    } on Failure catch (e) {
      return (null, e);
    }
  }
}

class CancelBookingUseCase {
  const CancelBookingUseCase();

  Future<Failure?> call(String id) async {
    try {
      await BookingRepository.instance.cancelBooking(id);
      return null;
    } on Failure catch (e) {
      return e;
    }
  }
}
