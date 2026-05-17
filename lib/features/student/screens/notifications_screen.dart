import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/student_provider.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentNotificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false,
      ),
      body: async.when(
        loading: () => const ShimmerList(count: 5, itemHeight: 80),
        error: (e, _) => AppError(message: e.toString()),
        data: (list) {
          if (list.isEmpty) return const Center(
            child: Text('No notifications', style: TextStyle(color: AppColors.textSecondary)));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _NotifCard(notif: list[i]),
          );
        },
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationModel notif;
  const _NotifCard({required this.notif});

  static const _typeColors = {
    'circular':    AppColors.primary,
    'announcement': Color(0xFF673AB7),
    'exam':        AppColors.attendanceRed,
    'fee':         Color(0xFF00897B),
    'general':     AppColors.textSecondary,
  };

  static const _typeIcons = {
    'circular':    Icons.article_outlined,
    'announcement': Icons.campaign_outlined,
    'exam':        Icons.assignment_outlined,
    'fee':         Icons.payments_outlined,
    'general':     Icons.notifications_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[notif.type] ?? AppColors.textSecondary;
    final icon  = _typeIcons[notif.type] ?? Icons.notifications_outlined;

    return Container(
      decoration: BoxDecoration(
        color: notif.isRead ? Colors.white : AppColors.primaryLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: notif.isRead ? AppColors.border : AppColors.primary.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(notif.title,
                style: TextStyle(
                  fontWeight: notif.isRead ? FontWeight.normal : FontWeight.w600,
                  fontSize: 14,
                ))),
            if (!notif.isRead)
              Container(width: 8, height: 8,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
          ]),
          const SizedBox(height: 4),
          Text(notif.body,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(notif.type.toUpperCase(),
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
            const Spacer(),
            Text(DateFormat('dd MMM, hh:mm a').format(notif.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
          ]),
        ])),
      ]),
    );
  }
}
