import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/download_service.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DownloadService>();
    final tasks = service.tasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('下载管理'),
        actions: [
          if (service.completedTasks.isNotEmpty)
            TextButton(
              onPressed: service.clearCompleted,
              child: const Text('清除已完成'),
            ),
        ],
      ),
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_done_rounded, size: 72, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('暂无下载任务', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _DownloadTile(task: task);
              },
            ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  final DownloadTask task;
  const _DownloadTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final service = context.read<DownloadService>();
    final colorScheme = Theme.of(context).colorScheme;

    IconData statusIcon;
    Color statusColor;
    String statusText;
    switch (task.status) {
      case DownloadStatus.downloading:
        statusIcon = Icons.downloading_rounded;
        statusColor = colorScheme.primary;
        statusText = '${(task.progress * 100).toStringAsFixed(0)}%';
        break;
      case DownloadStatus.completed:
        statusIcon = Icons.check_circle_rounded;
        statusColor = Colors.green;
        statusText = '已完成';
        break;
      case DownloadStatus.failed:
        statusIcon = Icons.error_rounded;
        statusColor = Colors.red;
        statusText = '失败';
        break;
      case DownloadStatus.paused:
        statusIcon = Icons.pause_circle_rounded;
        statusColor = Colors.orange;
        statusText = '已暂停';
        break;
      default:
        statusIcon = Icons.hourglass_empty_rounded;
        statusColor = Colors.grey;
        statusText = '排队中';
    }

    return ListTile(
      leading: task.iconUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: task.iconUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(Icons.android),
              ),
            )
          : const Icon(Icons.android),
      title: Text(task.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.status == DownloadStatus.downloading)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: LinearProgressIndicator(value: task.progress),
            ),
          Text(statusText, style: TextStyle(color: statusColor, fontSize: 12)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (task.status == DownloadStatus.downloading)
            IconButton(
              icon: const Icon(Icons.pause_rounded),
              onPressed: () => service.cancelDownload(task.id),
            ),
          if (task.status == DownloadStatus.completed && task.localPath != null)
            IconButton(
              icon: const Icon(Icons.folder_open_rounded),
              onPressed: () => service.openFile(task.localPath!),
            ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => service.removeTask(task.id),
          ),
        ],
      ),
    );
  }
}
