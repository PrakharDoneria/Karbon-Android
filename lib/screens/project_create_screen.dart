import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart'; // Import the glassmorphism library
import '../models/project.dart';
import '../services/api_service.dart';
import 'consultation_screen.dart';

// Define your color palette (consistent with the previous examples)
const Color primaryColor = Color(0xFF1E272E); // Dark charcoal
const Color secondaryColor = Color(0xFF2D3436); // Slightly lighter charcoal
const Color accentColor = Color(0xFF808e9b);   // Grayish-blue
const Color textColor = Colors.white70;         // Slightly transparent white

class ProjectCreateScreen extends StatefulWidget {
  final Function(Project, BuildContext) onProjectCreated;
  const ProjectCreateScreen({super.key, required this.onProjectCreated});

  @override
  State<ProjectCreateScreen> createState() => _ProjectCreateScreenState();
}

class _ProjectCreateScreenState extends State<ProjectCreateScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  bool isLoading = false;

  Future<void> createProject() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty || description.isEmpty) return;

    setState(() => isLoading = true);

    String? html = await ApiService.generateHtml(description);

    if (html?.contains('Rate limit') == true) {
      if (context.mounted) {
        final upgraded = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionConsultScreen()),
        );
        if (upgraded == true) {
          html = await ApiService.generateHtml(description);
        }
      }
    }

    if (html != null && !html.contains('Rate limit')) {
      final project = Project(name: name, description: description, htmlContent: html);
      widget.onProjectCreated(project, context);
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,  // Set the background color
      appBar: AppBar(
        backgroundColor: secondaryColor,
        title: Text('Create New Project', style: TextStyle(color: textColor)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GlassmorphicContainer(
              width: double.infinity,
              height: 60,
              borderRadius: 16,
              blur: 20,
              alignment: Alignment.bottomCenter,
              border: 2,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  secondaryColor.withOpacity(0.2),
                  secondaryColor.withOpacity(0.1),
                ],
                stops: const [
                  0.1,
                  0.9,
                ],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withOpacity(0.5),
                  accentColor.withOpacity(0.5),
                ],
              ),
              child: Center(
                child: TextField(
                  controller: nameController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Project Name',
                    labelStyle: TextStyle(color: textColor.withOpacity(0.8)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GlassmorphicContainer(
              width: double.infinity,
              height: 150, // Increased height for multiline input
              borderRadius: 16,
              blur: 20,
              alignment: Alignment.bottomCenter,
              border: 2,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  secondaryColor.withOpacity(0.2),
                  secondaryColor.withOpacity(0.1),
                ],
                stops: const [
                  0.1,
                  0.9,
                ],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withOpacity(0.5),
                  accentColor.withOpacity(0.5),
                ],
              ),
              child: Center(
                child: TextField(
                  controller: descriptionController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Project Description',
                    labelStyle: TextStyle(color: textColor.withOpacity(0.8)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  maxLines: 5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            isLoading
                ? CircularProgressIndicator(color: accentColor)
                : ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: textColor),
              onPressed: createProject,
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }
}