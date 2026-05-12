// Customer layout state.
// Remembers whether the customer sidebar is collapsed so the UI can keep the
// same layout choice while moving between customer screens.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True when the customer sidebar is collapsed.
final isCustomerSidebarCollapsedProvider = StateProvider<bool>((ref) => false);
