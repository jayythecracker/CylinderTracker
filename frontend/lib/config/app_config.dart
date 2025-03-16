class AppConfig {
  // Base API URL
  static const String baseUrl = 'http://localhost:8000/api';
  
  // Authentication endpoints
  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String profileEndpoint = '$baseUrl/auth/profile';
  static const String changePasswordEndpoint = '$baseUrl/auth/change-password';
  
  // User endpoints
  static const String usersEndpoint = '$baseUrl/users';
  
  // Factory endpoints
  static const String factoriesEndpoint = '$baseUrl/factories';
  
  // Cylinder endpoints
  static const String cylindersEndpoint = '$baseUrl/cylinders';
  static const String cylindersByQREndpoint = '$cylindersEndpoint/qr';
  
  // Customer endpoints
  static const String customersEndpoint = '$baseUrl/customers';
  
  // Filling endpoints
  static const String fillingLinesEndpoint = '$baseUrl/filling/lines';
  static const String fillingBatchesEndpoint = '$baseUrl/filling/batches';
  
  // Inspection endpoints
  static const String inspectionsEndpoint = '$baseUrl/inspection';
  
  // Sale endpoints
  static const String salesEndpoint = '$baseUrl/sales';
  
  // Report endpoints
  static const String reportsEndpoint = '$baseUrl/reports';
  static const String dailySalesReportEndpoint = '$reportsEndpoint/daily-sales';
  static const String monthlySalesReportEndpoint = '$reportsEndpoint/monthly-sales';
  static const String cylinderStatisticsEndpoint = '$reportsEndpoint/cylinder-statistics';
  static const String fillingReportEndpoint = '$reportsEndpoint/filling';
  static const String customerActivityReportEndpoint = '$reportsEndpoint/customer-activity';
  
  // Pagination defaults
  static const int defaultPageSize = 20;
  
  // Shared preferences keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';
  
  // Role constants
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';
  static const String roleFiller = 'filler';
  static const String roleSeller = 'seller';
  
  // Status constants
  static const List<String> cylinderStatuses = [
    'Empty', 'Full', 'In Filling', 'In Inspection', 'Error', 'In Delivery', 'Maintenance'
  ];
  
  static const List<String> fillingLineStatuses = [
    'Idle', 'Active', 'Maintenance'
  ];
  
  static const List<String> batchStatuses = [
    'In Progress', 'Completed', 'Failed'
  ];
  
  static const List<String> saleStatuses = [
    'Pending', 'In Progress', 'Delivered', 'Completed', 'Cancelled'
  ];
  
  static const List<String> paymentStatuses = [
    'Unpaid', 'Partial', 'Paid'
  ];
}
