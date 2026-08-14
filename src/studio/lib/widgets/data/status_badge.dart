import 'package:flutter/material.dart';

/// 状态徽章（正常/风险/待审批）。
enum StatusBadgeStatus { normal, risk, pending }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, required this.label});

  final StatusBadgeStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      StatusBadgeStatus.normal => Colors.grey.shade600,
      StatusBadgeStatus.risk => Colors.orange.shade800,
      StatusBadgeStatus.pending => Colors.blue.shade700,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
