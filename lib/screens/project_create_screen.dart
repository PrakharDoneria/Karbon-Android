import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../models/project.dart';
import '../services/api_service.dart';

const Color primaryColor = Color(0xFF1E272E);
const Color secondaryColor = Color(0xFF2D3436);
const Color accentColor = Color(0xFF808e9b);
const Color textColor = Colors.white70;

class ProjectCreateScreen extends StatefulWidget {
  final Function(Project, BuildContext) onProjectCreated;
  const ProjectCreateScreen({super.key, required this.onProjectCreated});

  @override
  State<ProjectCreateScreen> createState() => _ProjectCreateScreenState();
}

class _ProjectCreateScreenState extends State<ProjectCreateScreen> with SingleTickerProviderStateMixin {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> createProject() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty) {
      _showErrorSnackBar('Please enter a project name');
      return;
    }

    if (description.isEmpty) {
      _showErrorSnackBar('Please enter a project description');
      return;
    }

    setState(() => isLoading = true);

    try {
      String? html = await ApiService.generateHtml(description);

      if (html == null || html.contains('Rate limit')) {
        _showErrorSnackBar('API rate limit reached. Please try again later.');
        setState(() => isLoading = false);
        return;
      }

      final project = Project(name: name, description: description, htmlContent: html);
      widget.onProjectCreated(project, context);
    } catch (e) {
      _showErrorSnackBar('Failed to generate project: ${e.toString()}');
      setState(() => isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: primaryColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: BackButton(color: textColor),
        title: Text('Create New Project', style: TextStyle(color: textColor)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor,
              secondaryColor,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0), // Reduced padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeaderSection(),
                          const SizedBox(height: 20), // Reduced spacing
                          _buildNameField(),
                          const SizedBox(height: 16), // Reduced spacing
                          _buildDescriptionField(),
                          const SizedBox(height: 16), // Reduced spacing
                          _buildTipsSection(),
                          const SizedBox(height: 20), // Reduced spacing
                          _buildGenerateButton(),
                          const SizedBox(height: 16), // Added bottom padding
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            GlassmorphicContainer(
              width: 45, // Reduced size
              height: 45, // Reduced size
              borderRadius: 12,
              blur: 20,
              alignment: Alignment.center,
              border: 2,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  secondaryColor.withOpacity(0.2),
                  secondaryColor.withOpacity(0.1),
                ],
                stops: const [0.1, 0.9],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withOpacity(0.5),
                  accentColor.withOpacity(0.5),
                ],
              ),
              child: Icon(
                Icons.web_asset_rounded,
                size: 22, // Reduced size
                color: accentColor,
              ),
            ),
            const SizedBox(width: 14), // Reduced spacing
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'New Project',
                    style: TextStyle(
                      fontSize: 22, // Reduced font size
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Generate HTML from your description',
                    style: TextStyle(
                      fontSize: 13, // Reduced font size
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 6),
          child: Text(
            'PROJECT NAME',
            style: TextStyle(
              fontSize: 11, // Reduced font size
              fontWeight: FontWeight.w600,
              color: accentColor,
              letterSpacing: 1.2, // Reduced letter spacing
            ),
          ),
        ),
        GlassmorphicContainer(
          width: double.infinity,
          height: 52, // Reduced height
          borderRadius: 14,
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
            stops: const [0.1, 0.9],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withOpacity(0.5),
              accentColor.withOpacity(0.5),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: nameController,
              style: TextStyle(
                color: textColor,
                fontSize: 15, // Reduced font size
              ),
              decoration: InputDecoration(
                hintText: 'Enter project name',
                hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.folder_outlined,
                  color: accentColor.withOpacity(0.7),
                  size: 18, // Reduced size
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10), // Reduced padding
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 6),
          child: Text(
            'DESCRIPTION',
            style: TextStyle(
              fontSize: 11, // Reduced font size
              fontWeight: FontWeight.w600,
              color: accentColor,
              letterSpacing: 1.2, // Reduced letter spacing
            ),
          ),
        ),
        GlassmorphicContainer(
          width: double.infinity,
          height: 140, // Reduced height
          borderRadius: 14,
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
            stops: const [0.1, 0.9],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withOpacity(0.5),
              accentColor.withOpacity(0.5),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // Reduced vertical padding
            child: TextField(
              controller: descriptionController,
              style: TextStyle(
                color: textColor,
                fontSize: 15, // Reduced font size
                height: 1.3, // Reduced line height
              ),
              decoration: InputDecoration(
                hintText: 'Describe your project in detail...',
                hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
                border: InputBorder.none,
                alignLabelWithHint: true,
              ),
              maxLines: 5, // Reduced number of lines
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection() {
    // This is the problematic section
    return GlassmorphicContainer(
      width: double.infinity,
      height: 90, // Further reduced height
      borderRadius: 14,
      blur: 20,
      alignment: Alignment.bottomCenter,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentColor.withOpacity(0.15),
          accentColor.withOpacity(0.05),
        ],
        stops: const [0.1, 0.9],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentColor.withOpacity(0.4),
          accentColor.withOpacity(0.4),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0), // Further reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min, // Add this to prevent horizontal expansion
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: accentColor,
                  size: 14, // Further reduced size
                ),
                const SizedBox(width: 5), // Reduced spacing
                Text(
                  'TIPS FOR BETTER RESULTS',
                  style: TextStyle(
                    fontSize: 10, // Further reduced font size
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6), // Reduced spacing
            Flexible( // Added Flexible widget to allow text to adapt to available space
              child: Text(
                // Shortened the text to fit better
                '• Be specific about layout and colors\n• Mention special features\n• Consider responsive design',
                style: TextStyle(
                  fontSize: 12, // Further reduced font size
                  color: textColor.withOpacity(0.8),
                  height: 1.2, // Further reduced line height
                ),
                overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
                maxLines: 3, // Limit to 3 lines
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 46, // Reduced height
      child: isLoading
          ? GlassmorphicContainer(
        width: double.infinity,
        height: 46, // Reduced height
        borderRadius: 14,
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
          stops: const [0.1, 0.9],
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16, // Reduced size
                height: 16, // Reduced size
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              ),
              const SizedBox(width: 8), // Reduced spacing
              Text(
                'Generating...',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14, // Reduced font size
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      )
          : GlassmorphicContainer(
        width: double.infinity,
        height: 46, // Reduced height
        borderRadius: 14,
        blur: 20,
        alignment: Alignment.bottomCenter,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(0.3),
            accentColor.withOpacity(0.1),
          ],
          stops: const [0.1, 0.9],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.2),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: createProject,
            borderRadius: BorderRadius.circular(14),
            splashColor: Colors.white.withOpacity(0.1),
            highlightColor: Colors.white.withOpacity(0.05),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.code_rounded,
                    color: Colors.white,
                    size: 16, // Reduced size
                  ),
                  const SizedBox(width: 8), // Reduced spacing
                  Text(
                    'Generate HTML',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14, // Reduced font size
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}