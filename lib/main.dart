import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:glassmorphism/glassmorphism.dart';

import 'models/project.dart';
import 'screens/project_create_screen.dart';
import 'screens/project_view_screen.dart';

const Color primaryColor = Color(0xFF1E272E);
const Color secondaryColor = Color(0xFF2D3436);
const Color accentColor = Color(0xFF808e9b);
const Color textColor = Colors.white70;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Karbon',
      home: const HomeDecider(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: primaryColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        fontFamily: 'Roboto',
      ),
    );
  }
}

class HomeDecider extends StatefulWidget {
  const HomeDecider({super.key});

  @override
  State<HomeDecider> createState() => _HomeDeciderState();
}

class _HomeDeciderState extends State<HomeDecider> with TickerProviderStateMixin {
  Project? project;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadProject();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProject() async {
    await Future.delayed(const Duration(milliseconds: 800));

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/project.json');

    if (await file.exists()) {
      final content = await file.readAsString();
      final jsonData = json.decode(content);
      project = Project.fromJson(jsonData);

      WidgetsBinding.instance.addPostFrameCallback((_) => _askResumeOrNew());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToCreateScreen());
    }
  }

  void _askResumeOrNew() async {
    final choice = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GlassmorphicContainer(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.4,
                borderRadius: 20,
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
                    ]),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withOpacity(0.5),
                    accentColor.withOpacity(0.5),
                  ],
                ),
                child:  Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: secondaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.work_outline,
                          size: 48,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Resume or New?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You were working on a project.\nWhat would you like to do?',
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor.withOpacity(0.8),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: _GlassButton(
                              onPressed: () => Navigator.pop(context, 'new'),
                              child: Text(
                                'New Project',
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _GlassButton(
                              onPressed: () => Navigator.pop(context, 'resume'),
                              isPrimary: true,
                              child: const Text(
                                'Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!mounted) return;

    if (choice == 'resume') {
      _goToViewScreen(project!);
    } else {
      _goToCreateScreen();
    }
  }

  void _goToViewScreen(Project proj) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProjectViewScreen(project: proj),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _goToCreateScreen() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProjectCreateScreen(
              onProjectCreated: (proj, buildCtx) async {
                final dir = await getApplicationDocumentsDirectory();
                final file = File('${dir.path}/project.json');
                await file.writeAsString(json.encode(proj.toJson()));

                if (buildCtx.mounted) {
                  Navigator.pushReplacement(
                    buildCtx,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          ProjectViewScreen(project: proj),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.1),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            )),
                            child: child,
                          ),
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 600),
                    ),
                  );
                }
              },
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor,
              secondaryColor,
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GlassmorphicContainer(
                        width: 128,
                        height: 128,
                        borderRadius: 32,
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
                            ]),
                        borderGradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accentColor.withOpacity(0.5),
                            accentColor.withOpacity(0.5),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Icon(
                            Icons.code,
                            size: 64,
                            color: accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Karbon',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Code Generator',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor.withOpacity(0.8),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 48),
                      GlassmorphicContainer(
                        width: 200,
                        height: 120,
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
                            ]),
                        borderGradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accentColor.withOpacity(0.5),
                            accentColor.withOpacity(0.5),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading...',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool isPrimary;

  const _GlassButton({
    required this.onPressed,
    required this.child,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = isPrimary ? Colors.white.withOpacity(0.25) : secondaryColor.withOpacity(0.15);
    final borderColor = isPrimary ? Colors.white.withOpacity(0.3) : accentColor.withOpacity(0.2);

    return GlassmorphicContainer(
      width: double.infinity,
      height: 50,
      borderRadius: 16,
      blur: 20,
      alignment: Alignment.bottomCenter,
      border: 2,
      linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            buttonColor,
            buttonColor.withOpacity(0.5),
          ],
          stops: const [
            0.1,
            0.9,
          ]),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          borderColor,
          borderColor,
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}