import 'package:flutter/material.dart';
import '../models/project.dart';

class ProjectTile extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const ProjectTile({
    super.key,
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(project.name),
      subtitle: Text(project.description),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
