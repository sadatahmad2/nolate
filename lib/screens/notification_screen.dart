import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  static int get unreadCount {
    return _NotificationScreenState.getUnreadCount();
  }

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Static dummy notification data so it persists when screen is closed and reopened
  static final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'icon': Icons.celebration_outlined,
      'iconColor': Colors.green,
      'title': 'Welcome to Nolate!',
      'description': 'Enjoy super fast 15-min delivery for all your daily needs.',
      'time': 'Just now',
      'isUnread': true,
    },
  ];

  static int getUnreadCount() {
    return _notifications.where((notif) => notif['isUnread'] == true).length;
  }

  void _markAllAsRead() {
    setState(() {
      for (var notif in _notifications) {
        notif['isUnread'] = false;
      }
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((notif) => notif['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text('Mark all as read', style: TextStyle(color: Color(0xFF059669), fontSize: 12)),
          )
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.black26),
                  const SizedBox(height: 16),
                  const Text('No notifications', style: TextStyle(color: Colors.black54, fontSize: 16)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == _notifications.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text(
                        "You're all caught up!",
                        style: TextStyle(color: Colors.black45, fontSize: 13),
                      ),
                    ),
                  );
                }

                final notif = _notifications[index];
                return Dismissible(
                  key: Key(notif['id']),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _deleteNotification(notif['id']);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification deleted'), duration: Duration(seconds: 2)),
                    );
                  },
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  child: _buildNotificationItem(
                    icon: notif['icon'],
                    iconColor: notif['iconColor'],
                    title: notif['title'],
                    description: notif['description'],
                    time: notif['time'],
                    isUnread: notif['isUnread'],
                    onDelete: () => _deleteNotification(notif['id']),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String time,
    required bool isUnread,
    required VoidCallback onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isUnread ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUnread ? Colors.black.withOpacity(0.05) : Colors.transparent),
        boxShadow: isUnread
            ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(Icons.close, size: 16, color: Colors.black38),
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
