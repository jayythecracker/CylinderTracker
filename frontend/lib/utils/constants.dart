import 'package:flutter/material.dart';

// Colors
const Color kPrimaryColor = Color(0xFF2F80ED);
const Color kSecondaryColor = Color(0xFF4CAF50);
const Color kBackgroundColor = Color(0xFFF9FAFB);
const Color kBorderColor = Color(0xFFE0E0E0);
const Color kErrorColor = Color(0xFFEB5757);
const Color kWarningColor = Color(0xFFF2994A);
const Color kSuccessColor = Color(0xFF27AE60);
const Color kGreyColor = Color(0xFF828282);
const Color kGreyLightColor = Color(0xFFF2F2F2);
const Color kGreyDarkColor = Color(0xFF4F4F4F);

// Cylinder Status Colors
const Color kCylinderEmptyColor = Color(0xFFE0E0E0);
const Color kCylinderFullColor = Color(0xFF4CAF50);
const Color kCylinderErrorColor = Color(0xFFF44336);
const Color kCylinderInTransitColor = Color(0xFF2196F3);
const Color kCylinderInMaintenanceColor = Color(0xFFFF9800);
const Color kCylinderInFillingColor = Color(0xFF9C27B0);
const Color kCylinderInInspectionColor = Color(0xFFFFEB3B);

// Text Styles
const TextStyle kHeadingTextStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: Colors.black,
);

const TextStyle kSubheadingTextStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: Colors.black,
);

const TextStyle kBodyTextStyle = TextStyle(
  fontSize: 16,
  color: Colors.black,
);

const TextStyle kButtonTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: Colors.white,
);

const TextStyle kCaptionTextStyle = TextStyle(
  fontSize: 12,
  color: kGreyColor,
);

// Padding
const double kDefaultPadding = 16.0;
const EdgeInsets kScreenPadding = EdgeInsets.all(kDefaultPadding);
const EdgeInsets kCardPadding = EdgeInsets.all(16.0);

// Border Radius
const double kDefaultBorderRadius = 8.0;
const double kCardBorderRadius = 12.0;
const BorderRadius kBorderRadius = BorderRadius.all(Radius.circular(kDefaultBorderRadius));
const BorderRadius kCardBorderRadius2 = BorderRadius.all(Radius.circular(kCardBorderRadius));

// Shadows
const List<BoxShadow> kDefaultShadow = [
  BoxShadow(
    color: Color(0x1A000000),
    offset: Offset(0, 2),
    blurRadius: 4,
    spreadRadius: 0,
  )
];

// Animations
const Duration kDefaultAnimationDuration = Duration(milliseconds: 300);

// Gas Type Names
const Map<String, String> kGasTypeNames = {
  'Medical': 'Medical',
  'Industrial': 'Industrial',
};

// Customer Type Names
const Map<String, String> kCustomerTypeNames = {
  'Hospital': 'Hospital',
  'Individual': 'Individual',
  'Shop': 'Shop',
  'Factory': 'Factory',
  'Workshop': 'Workshop',
};

// Role Names
const Map<String, String> kRoleNames = {
  'Admin': 'Administrator',
  'Manager': 'Manager',
  'Filler': 'Gas Filler',
  'Seller': 'Sales Agent',
};

// Cylinder Status Names
const Map<String, String> kCylinderStatusNames = {
  'Empty': 'Empty',
  'Full': 'Full',
  'Error': 'Error',
  'InTransit': 'In Transit',
  'InMaintenance': 'In Maintenance',
  'InFilling': 'In Filling',
  'InInspection': 'In Inspection',
};

// Status Colors
final Map<String, Color> kCylinderStatusColors = {
  'Empty': kCylinderEmptyColor,
  'Full': kCylinderFullColor,
  'Error': kCylinderErrorColor,
  'InTransit': kCylinderInTransitColor,
  'InMaintenance': kCylinderInMaintenanceColor,
  'InFilling': kCylinderInFillingColor,
  'InInspection': kCylinderInInspectionColor,
};

// App-specific constants
const int kDefaultPageSize = 20;
const int kMaxCylindersPerLine = 10;
