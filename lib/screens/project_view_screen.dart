import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:glassmorphism/glassmorphism.dart'; // Import the glassmorphism library
import '../models/project.dart';
import '../services/api_service.dart';

// Define your color palette (consistent with the previous example)
const Color primaryColor = Color(0xFF1E272E); // Dark charcoal
const Color secondaryColor = Color(0xFF2D3436); // Slightly lighter charcoal
const Color accentColor = Color(0xFF808e9b);   // Grayish-blue
const Color textColor = Colors.white70;         // Slightly transparent white

class ProjectViewScreen extends StatefulWidget {
  final Project project;

  const ProjectViewScreen({super.key, required this.project});

  @override
  State<ProjectViewScreen> createState() => _ProjectViewScreenState();
}

class _ProjectViewScreenState extends State<ProjectViewScreen> {
  final TextEditingController instructionController = TextEditingController();
  bool isUpdating = false;
  int currentTabIndex = 0;

  late InAppWebViewController webViewController;
  final List<String> consoleLogs = [];

  Future<void> exportProject() async {
    try {
      final dir = await getExternalStorageDirectory(); // App-specific directory
      if (dir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get export directory.')),
        );
        return;
      }

      final exportDir = Directory('${dir.path}/ExportedProjects');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final file = File('${exportDir.path}/${widget.project.name}.html');
      await file.writeAsString(widget.project.htmlContent);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to ${file.path}')),
      );

      // Optional: Offer to open or edit the file using HTML Editor PRO
      final shouldDownload = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: secondaryColor,  // Match background color
          title: Text('Edit in HTML Editor PRO?', style: TextStyle(color: textColor)),
          content: Text(
            'To edit exported files, install "HTML Editor PRO" from the Play Store. Would you like to download it now?',
            style: TextStyle(color: textColor.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: accentColor)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              child: const Text('Download'),
            ),
          ],
        ),
      );

      if (shouldDownload == true) {
        const url = 'https://play.google.com/store/apps/details?id=com.protecgames.htmleditorpro';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('Export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export file.')),
      );
    }
  }

  Future<void> updateProjectWithInstruction() async {
    final instruction = instructionController.text.trim();
    if (instruction.isEmpty) return;

    setState(() => isUpdating = true);

    final updatedHtml = await ApiService.generateHtml(instruction);
    if (updatedHtml != null) {
      setState(() {
        widget.project.htmlContent = updatedHtml;
        instructionController.clear();
      });
      webViewController.loadData(
        data: updatedHtml,
        mimeType: 'text/html',
        encoding: 'utf-8',
      );
    }

    setState(() => isUpdating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,  // set the background color here
      appBar: AppBar(
        backgroundColor: secondaryColor,  // set the appbar color here
        title: Text(widget.project.name, style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor), // Color of the back arrow
        actions: [
          IconButton(
            onPressed: exportProject,
            icon: Icon(Icons.download, color: textColor),
          )
        ],
      ),
      body: IndexedStack(
        index: currentTabIndex,
        children: [
          Column(
            children: [
              Expanded(
                child: InAppWebView(
                  initialData: InAppWebViewInitialData(
                    data: widget.project.htmlContent,
                    mimeType: 'text/html',
                    encoding: 'utf-8',
                  ),
                  initialOptions: InAppWebViewGroupOptions(
                    crossPlatform: InAppWebViewOptions(
                      javaScriptEnabled: true,
                      useShouldOverrideUrlLoading: true,
                      mediaPlaybackRequiresUserGesture: false,
                    ),
                  ),
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    setState(() {
                      consoleLogs.add(consoleMessage.message);
                    });
                    debugPrint('JS: ${consoleMessage.message}');
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: secondaryColor.withOpacity(0.3), // Semi-transparent background
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: instructionController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Update instruction...',
                          hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    isUpdating
                        ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
                    )
                        : IconButton(
                      icon: Icon(Icons.send, color: textColor),
                      onPressed: updateProjectWithInstruction,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: secondaryColor, // Optional: give the logs container a background color
            child: consoleLogs.isEmpty
                ? Center(child: Text("No console logs yet", style: TextStyle(color: textColor)))
                : ListView.builder(
              itemCount: consoleLogs.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  consoleLogs[index],
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container( // Added Container
        decoration: BoxDecoration( // Added BoxDecoration
          color: secondaryColor, // Set background color
          border: Border(top: BorderSide(color: accentColor.withOpacity(0.2), width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: textColor,
          unselectedItemColor: accentColor,
          currentIndex: currentTabIndex,
          onTap: (index) {
            setState(() => currentTabIndex = index);
          },
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.preview),
              label: 'Preview',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.terminal),
              label: 'Logs',
            ),
          ],
        ),
      ),
    );
  }
}