
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persists customer sidebar collapse state across customer screens.
final isCustomerSidebarCollapsedProvider =
    StateProvider<bool>((ref) => false);
