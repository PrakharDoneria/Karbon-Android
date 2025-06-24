import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:file_picker/file_picker.dart';
import '../models/project.dart';
import '../services/api_service.dart';

const Color primaryColor = Color(0xFF0A192F);
const Color secondaryColor = Color(0xFF172A45);
const Color accentColor = Color(0xFF64FFDA);
const Color accentColorAlt = Color(0xFF00BFFF);
const Color textColor = Colors.white;

class ProjectViewScreen extends StatefulWidget {
  final Project project;

  const ProjectViewScreen({super.key, required this.project});

  @override
  State<ProjectViewScreen> createState() => _ProjectViewScreenState();
}

class _ProjectViewScreenState extends State<ProjectViewScreen> with SingleTickerProviderStateMixin {
  final TextEditingController instructionController = TextEditingController();
  bool isUpdating = false;
  int currentTabIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late InAppWebViewController webViewController;
  final List<String> consoleLogs = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    instructionController.dispose();
    super.dispose();
  }

  Future<void> exportProject() async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Project As',
        fileName: '${widget.project.name}.html',
        type: FileType.custom,
        allowedExtensions: ['html'],
      );

      if (result == null) {
        _showSnackBar('Export cancelled.');
        return;
      }

      final file = File(result);
      await file.writeAsString(widget.project.htmlContent);

      if (!mounted) return;
      _showSnackBar('Exported to ${file.path}');

      final shouldDownload = await showDialog<bool>(
        context: context,
        builder: (ctx) => _buildExportDialog(),
      );

      if (shouldDownload == true) {
        const url = 'https://play.google.com/store/apps/details?id=com.protecgames.htmleditorpro';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('Export error: $e');
      _showSnackBar('Failed to export file.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, color: accentColor, size: 18),
            const SizedBox(width: 8),
            Flexible(child: Text(message, overflow: TextOverflow.ellipsis)),
          ],
        ),
        backgroundColor: secondaryColor.withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
        ),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildExportDialog() {
    return AlertDialog(
      backgroundColor: secondaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accentColor.withOpacity(0.5), width: 1),
      ),
      title: Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.code_rounded, color: accentColor),
          ),
          const Text(
            'Edit in HTML Editor PRO?',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Text(
        'To edit exported files, install "HTML Editor PRO" from the Play Store. Would you like to download it now?',
        style: TextStyle(color: textColor.withOpacity(0.9)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: textColor.withOpacity(0.7)),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: primaryColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.download_rounded, size: 16),
              const SizedBox(width: 6),
              const Text('Download', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
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
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: secondaryColor,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Shimmer.fromColors(
              baseColor: accentColor,
              highlightColor: accentColorAlt,
              period: const Duration(seconds: 3),
              child: const Icon(Icons.code, size: 20),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.project.name,
                style: const TextStyle(color: textColor, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: accentColor),
        actions: [
          IconButton(
            onPressed: exportProject,
            icon: const Icon(Icons.rocket_launch_rounded),
            tooltip: 'Export project',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: currentTabIndex,
              children: [
                buildWebView(),
                buildConsoleLogs(),
              ],
            ),
          ),
          buildInstructionBar(),
        ],
      ),
      bottomNavigationBar: buildBottomBar(),
    );
  }

  Widget buildWebView() {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
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
            onWebViewCreated: (controller) => webViewController = controller,
            onConsoleMessage: (controller, consoleMessage) {
              setState(() {
                consoleLogs.add(consoleMessage.message);
              });
              debugPrint('JS: ${consoleMessage.message}');
            },
          ),
        ),
        Positioned(
          top: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: secondaryColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.remove_red_eye_rounded, color: accentColor, size: 14),
                const SizedBox(width: 4),
                const Text('Preview', style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildConsoleLogs() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.1), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: consoleLogs.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Icon(Icons.terminal_rounded, size: 48, color: accentColor.withOpacity(0.3)),
            ),
            const SizedBox(height: 16),
            Text("No console logs yet", style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14)),
            const SizedBox(height: 8),
            Shimmer.fromColors(
              baseColor: textColor.withOpacity(0.3),
              highlightColor: accentColor.withOpacity(0.5),
              child: Text("Console output will appear here", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12)),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: consoleLogs.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.data_array_rounded, size: 16, color: accentColor.withOpacity(0.7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(consoleLogs[index], style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: textColor)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInstructionBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 10, spreadRadius: 0),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.code_rounded, color: accentColor.withOpacity(0.7), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: instructionController,
              style: const TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Update instruction...',
                hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => updateProjectWithInstruction(),
            ),
          ),
          const SizedBox(width: 8),
          isUpdating
              ? SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(accentColor)),
          )
              : Material(
            color: accentColor,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: updateProjectWithInstruction,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Transform.rotate(
                  angle: -math.pi / 4,
                  child: const Icon(Icons.send_rounded, color: primaryColor, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: secondaryColor,
        border: Border(top: BorderSide(color: accentColor.withOpacity(0.1), width: 1)),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: accentColor,
        unselectedItemColor: textColor.withOpacity(0.5),
        currentIndex: currentTabIndex,
        onTap: (index) => setState(() => currentTabIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.code_rounded),
            activeIcon: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(colors: [accentColor, accentColorAlt], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(bounds);
              },
              child: const Icon(Icons.code_rounded),
            ),
            label: 'Preview',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.terminal_rounded),
            activeIcon: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(colors: [accentColor, accentColorAlt], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(bounds);
              },
              child: const Icon(Icons.terminal_rounded),
            ),
            label: 'Logs',
          ),
        ],
      ),
    );
  }
}
