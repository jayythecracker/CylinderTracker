import 'package:flutter/material.dart';
import 'package:cylinder_management/config/app_config.dart';
import 'package:cylinder_management/models/cylinder.dart';
import 'package:intl/intl.dart';

class CylinderCard extends StatelessWidget {
  final Cylinder cylinder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final List<Widget>? actions;

  const CylinderCard({
    Key? key,
    required this.cylinder,
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
            // Header with status
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppConfig.getStatusColor(cylinder.status).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12.0),
                  topRight: Radius.circular(12.0),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16.0,
                    backgroundColor: AppConfig.getStatusColor(cylinder.status),
                    child: Icon(
                      _getStatusIcon(cylinder.status),
                      color: Colors.white,
                      size:
                        18.0,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      cylinder.serialNumber,
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
                      color: AppConfig.getStatusColor(cylinder.status),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      cylinder.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
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
                          'Type',
                          cylinder.type,
                          Icons.category_outlined,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          'Size',
                          cylinder.size,
                          Icons.straighten_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Working Pressure',
                          '${cylinder.workingPressure} bar',
                          Icons.speed_outlined,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          'Design Pressure',
                          '${cylinder.designPressure} bar',
                          Icons.design_services_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  _buildInfoItem(
                    'Factory',
                    cylinder.factory?.name ?? 'Unknown Factory',
                    Icons.business_outlined,
                  ),
                  if (cylinder.lastFilled != null) ...[
                    const SizedBox(height: 8.0),
                    _buildInfoItem(
                      'Last Filled',
                      DateFormat('MMM dd, yyyy').format(cylinder.lastFilled!),
                      Icons.local_gas_station_outlined,
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

  Widget _buildInfoItem(String label, String value, IconData icon) {
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
                style: const TextStyle(
                  fontSize: 14.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'empty':
        return Icons.battery_0_bar;
      case 'full':
        return Icons.battery_full;
      case 'error':
        return Icons.error_outline;
      case 'inmaintenance':
        return Icons.build;
      case 'intransit':
        return Icons.local_shipping;
      default:
        return Icons.help_outline;
    }
  }
}
