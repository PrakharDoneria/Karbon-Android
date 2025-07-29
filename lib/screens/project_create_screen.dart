import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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

class _ProjectCreateScreenState extends State<ProjectCreateScreen>
    with SingleTickerProviderStateMixin {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // AdMob variables
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _isAdLoading = false; //Prevent multiple ad loads.
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isProjectCreated = false;

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
    _loadRewardedAd();
    _loadBannerAd();
    _loadInterstitialAd();
  }

  // Platform check for ad unit id (replace with your actual ad units)
  String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5500303894286506/2582418347';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-5500303894286506/2582418347';
    } else {
      return ''; // Return empty string for other platforms
    }
  }

  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5500303894286506/7976562867';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-5500303894286506/7976562867';
    } else {
      return ''; // Return empty string for other platforms
    }
  }

  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-5500303894286506/3209104301';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-5500303894286506/3209104301';
    } else {
      return ''; // Return empty string for other platforms
    }
  }

  // Load Rewarded Ad
  void _loadRewardedAd() {
    if (_isAdLoading) return; // Prevent multiple ad loads at the same time
    _isAdLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('$ad loaded.');
          setState(() {
            _rewardedAd = ad;
            _isAdLoaded = true;
          });
          _isAdLoading = false;
          _setFullScreenContentCallback();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
          setState(() {
            _rewardedAd = null;
            _isAdLoaded = false;
          });
          _isAdLoading = false;
        },
      ),
    );
  }

  // Load Banner Ad
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('$ad loaded.');
          setState(() {});
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('Ad failed to load: $error');
          ad.dispose();
          setState(() {
            _bannerAd = null;
          });
        },
        onAdOpened: (Ad ad) => debugPrint('$ad opened.'),
        onAdClosed: (Ad ad) => debugPrint('$ad closed.'),
      ),
    );

    _bannerAd!.load();
  }

  // Load Interstitial Ad
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _setInterstitialFullScreenContentCallback();
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('InterstitialAd failed to load: $error.');
          _interstitialAd = null;
        },
      ),
    );
  }

  // Set Interstitial Ad Full Screen Content Callback
  void _setInterstitialFullScreenContentCallback() {
    if (_interstitialAd == null) return;
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          print('$ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _loadInterstitialAd(); // Load a new ad after dismissal
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _loadInterstitialAd(); // Attempt to load a new ad after failure
      },
    );
  }

  // Set Full Screen Content Callback
  void _setFullScreenContentCallback() {
    if (_rewardedAd == null) return;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          debugPrint('$ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        setState(() {
          _rewardedAd!.dispose();
          _rewardedAd = null;
          _isAdLoaded = false;
        });
        _loadRewardedAd(); // Load a new ad after dismissal
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        setState(() {
          _rewardedAd!.dispose();
          _rewardedAd = null;
          _isAdLoaded = false;
        });
        _loadRewardedAd(); // Attempt to load a new ad after failure
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    _animationController.dispose();
    _rewardedAd?.dispose(); // Dispose of the ad
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  // Function to display the rewarded ad and handle the reward
  Future<void> _showRewardedAd() async {
    if (_rewardedAd != null && _isAdLoaded) {
      _rewardedAd!.show(
          onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
            debugPrint(
                '$ad with reward $RewardItem(${reward.amount}, ${reward.type})');
            createProjectAfterAd(); //Call the actual project creation logic here AFTER the ad is viewed
          });
    } else {
      // If the ad isn't ready, show an error message or retry
      _showErrorSnackBar(
          'Ad is not ready yet. Please try again in a few seconds.');
      _loadRewardedAd(); // try to reload the ad.
      setState(() => isLoading = false); //Reset loading state.
    }
  }

  Future<void> createProjectAfterAd() async {
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

      final project = Project(
          name: name, description: description, htmlContent: html);
      widget.onProjectCreated(project, context);
      setState(() {
        _isProjectCreated = true;
      });
      _showInterstitialAd();
    } catch (e) {
      _showErrorSnackBar('Failed to generate project: ${e.toString()}');
      setState(() => isLoading = false);
    }
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      print("Interstitial ad is not ready yet.");
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
      body: Stack(children: [
        Container(
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
                            if (_bannerAd != null)
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: SizedBox(
                                  width: _bannerAd!.size.width.toDouble(),
                                  height: _bannerAd!.size.height.toDouble(),
                                  child: AdWidget(ad: _bannerAd!),
                                ),
                              ),
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
      ]),
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
                contentPadding:
                const EdgeInsets.symmetric(vertical: 10), // Reduced padding
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              mainAxisSize: MainAxisSize.min,
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
            Flexible(
              child: Text(
                '• Be specific about layout and colors\n• Mention special features\n• Consider responsive design',
                style: TextStyle(
                  fontSize: 12, // Further reduced font size
                  color: textColor.withOpacity(0.8),
                  height: 1.2, // Further reduced line height
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
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
            onTap: () {
              setState(() => isLoading = true);
              _showRewardedAd();
            },
            borderRadius: BorderRadius.circular(14),
            splashColor: Colors.white.withOpacity(0.1),
            highlightColor: Colors.white.withOpacity(0.05),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 16, // Reduced size
                  ),
                  const SizedBox(width: 8), // Reduced spacing
                  Text(
                    'Watch Ad to Generate',
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