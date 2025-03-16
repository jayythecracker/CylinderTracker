import 'package:flutter/material.dart';
import 'package:cylinder_management/config/app_config.dart';
import 'package:cylinder_management/models/customer.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final List<Widget>? actions;

  const CustomerCard({
    Key? key,
    required this.customer,
    this.onTap,
    this.onLongPress,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with customer type and status
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: _getCustomerTypeColor(customer.type).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12.0),
                  topRight: Radius.circular(12.0),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16.0,
                    backgroundColor: _getCustomerTypeColor(customer.type),
                    child: Icon(
                      _getCustomerTypeIcon(customer.type),
                      color: Colors.white,
                      size: 18.0,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: _getCustomerTypeColor(customer.type),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      customer.type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                  if (!customer.active) ...[
                    const SizedBox(width: 8.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: const Text(
                        'Inactive',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Body with details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Contact',
                          customer.contact,
                          Icons.phone_outlined,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          'Payment Type',
                          customer.paymentType,
                          Icons.payment_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  _buildInfoItem(
                    'Address',
                    customer.address,
                    Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Price Group',
                          customer.priceGroup,
                          Icons.sell_outlined,
                        ),
                      ),
                      if (customer.balance > 0)
                        Expanded(
                          child: _buildInfoItem(
                            'Balance',
                            '\$${customer.balance.toStringAsFixed(2)}',
                            Icons.account_balance_wallet_outlined,
                            textColor: customer.balance > 0 ? Colors.red : null,
                          ),
                        ),
                    ],
                  ),
                  if (customer.totalSales != null || customer.totalAmount != null) ...[
                    const SizedBox(height: 8.0),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        if (customer.totalSales != null)
                          Expanded(
                            child: _buildInfoItem(
                              'Total Sales',
                              customer.totalSales.toString(),
                              Icons.shopping_cart_outlined,
                            ),
                          ),
                        if (customer.totalAmount != null)
                          Expanded(
                            child: _buildInfoItem(
                              'Total Amount',
                              '\$${customer.totalAmount!.toStringAsFixed(2)}',
                              Icons.attach_money_outlined,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Actions
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, {Color? textColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16.0,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.0,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getCustomerTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'hospital':
        return Colors.red;
      case 'individual':
        return Colors.blue;
      case 'shop':
        return Colors.green;
      case 'factory':
        return Colors.purple;
      case 'workshop':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getCustomerTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hospital':
        return Icons.local_hospital;
      case 'individual':
        return Icons.person;
      case 'shop':
        return Icons.storefront;
      case 'factory':
        return Icons.factory;
      case 'workshop':
        return Icons.home_repair_service;
      default:
        return Icons.business;
    }
  }
}
