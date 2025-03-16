import 'package:flutter/material.dart';

import '../models/cylinder.dart';
import '../models/customer.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/cylinder/cylinder_list_screen.dart';
import '../screens/cylinder/cylinder_detail_screen.dart';
import '../screens/customer/customer_list_screen.dart';
import '../screens/customer/customer_detail_screen.dart';
import '../screens/filling/filling_screen.dart';
import '../screens/inspection/inspection_screen.dart';
import '../screens/sales/sales_screen.dart';
import '../screens/report/report_screen.dart';

class AppRouter {
  // Route names
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String cylinderListRoute = '/cylinders';
  static const String cylinderDetailRoute = '/cylinders/detail';
  static const String customerListRoute = '/customers';
  static const String customerDetailRoute = '/customers/detail';
  static const String fillingRoute = '/filling';
  static const String inspectionRoute = '/inspection';
  static const String salesRoute = '/sales';
  static const String reportRoute = '/reports';

  // Route generation
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case dashboardRoute:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      
      case cylinderListRoute:
        return MaterialPageRoute(builder: (_) => const CylinderListScreen());
      
      case cylinderDetailRoute:
        final Cylinder? cylinder = settings.arguments as Cylinder?;
        return MaterialPageRoute(
          builder: (_) => CylinderDetailScreen(cylinder: cylinder),
        );
      
      case customerListRoute:
        return MaterialPageRoute(builder: (_) => const CustomerListScreen());
      
      case customerDetailRoute:
        final Customer? customer = settings.arguments as Customer?;
        return MaterialPageRoute(
          builder: (_) => CustomerDetailScreen(customer: customer),
        );
      
      case fillingRoute:
        return MaterialPageRoute(builder: (_) => const FillingScreen());
      
      case inspectionRoute:
        return MaterialPageRoute(builder: (_) => const InspectionScreen());
      
      case salesRoute:
        return MaterialPageRoute(builder: (_) => const SalesScreen());
      
      case reportRoute:
        return MaterialPageRoute(builder: (_) => const ReportScreen());
      
      default:
        // If route is not found, redirect to login
        return MaterialPageRoute(
          builder: (_) => const Center(
            child: Text('Route not found!'),
          ),
        );
    }
  }
}
