import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/animated_rotation_widget.dart';
import 'package:flutter_hbb/common/widgets/custom_password.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:flutter_hbb/plugin/ui_manager.dart';
import 'package:flutter_hbb/utils/multi_window_manager.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart' as window_size;
import '../widgets/button.dart';

class DesktopHomePage extends StatefulWidget {
  const DesktopHomePage({Key? key}) : super(key: key);

  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

const borderColor = Color(0xFF2F65BA);

class _DesktopHomePageState extends State<DesktopHomePage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver, TickerProviderStateMixin {
  final _leftPaneScrollController = ScrollController();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _logoController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoAnimation;

  @override
  bool get wantKeepAlive => true;
  var systemError = '';
  StreamSubscription? _uniLinksSubscription;
  var svcStopped = false.obs;
  var watchIsCanScreenRecording = false;
  var watchIsProcessTrust = false;
  var watchIsInputMonitoring = false;
  var watchIsCanRecordAudio = false;
  Timer? _updateTimer;
  bool isCardClosed = false;

  final RxBool _editHover = false.obs;
  final RxBool _block = false.obs;
  final GlobalKey _childKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _logoAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _logoController.forward();

    _updateTimer = periodic_immediate(const Duration(seconds: 1), () async {
      await gFFI.serverModel.fetchID();
      final error = await bind.mainGetError();
      if (systemError != error) {
        systemError = error;
        setState(() {});
      }
      final v = await mainGetBoolOption(kOptionStopService);
      if (v != svcStopped.value) {
        svcStopped.value = v;
        setState(() {});
      }
      if (watchIsCanScreenRecording) {
        if (bind.mainIsCanScreenRecording(prompt: false)) {
          watchIsCanScreenRecording = false;
          setState(() {});
        }
      }
      if (watchIsProcessTrust) {
        if (bind.mainIsProcessTrusted(prompt: false)) {
          watchIsProcessTrust = false;
          setState(() {});
        }
      }
      if (watchIsInputMonitoring) {
        if (bind.mainIsCanInputMonitoring(prompt: false)) {
          watchIsInputMonitoring = false;
          setState(() {});
        }
      }
      if (watchIsCanRecordAudio) {
        if (isMacOS) {
          Future.microtask(() async {
            if ((await osxCanRecordAudio() ==
                PermissionAuthorizeType.authorized)) {
              watchIsCanRecordAudio = false;
              setState(() {});
            }
          });
        } else {
          watchIsCanRecordAudio = false;
          setState(() {});
        }
      }
    });
    Get.put<RxBool>(svcStopped, tag: 'stop-service');
    rustDeskWinManager.registerActiveWindowListener(onActiveWindowChanged);

    // Setup method handlers and other initialization...
    _setupMethodHandlers();
    _uniLinksSubscription = listenUniLinks();

    if (bind.isIncomingOnly()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateWindowSize();
      });
    }
    WidgetsBinding.instance.addObserver(this);
  }

  void _setupMethodHandlers() {
    screenToMap(window_size.Screen screen) => {
          'frame': {
            'l': screen.frame.left,
            't': screen.frame.top,
            'r': screen.frame.right,
            'b': screen.frame.bottom,
          },
          'visibleFrame': {
            'l': screen.visibleFrame.left,
            't': screen.visibleFrame.top,
            'r': screen.visibleFrame.right,
            'b': screen.visibleFrame.bottom,
          },
          'scaleFactor': screen.scaleFactor,
        };

    rustDeskWinManager.setMethodHandler((call, fromWindowId) async {
      debugPrint(
          "[Main] call ${call.method} with args ${call.arguments} from window $fromWindowId");
      if (call.method == kWindowMainWindowOnTop) {
        windowOnTop(null);
      } else if (call.method == kWindowGetWindowInfo) {
        final screen = (await window_size.getWindowInfo()).screen;
        if (screen == null) {
          return '';
        } else {
          return jsonEncode(screenToMap(screen));
        }
      } else if (call.method == kWindowGetScreenList) {
        return jsonEncode(
            (await window_size.getScreenList()).map(screenToMap).toList());
      } else if (call.method == kWindowActionRebuild) {
        reloadCurrentWindow();
      } else if (call.method == kWindowEventShow) {
        await rustDeskWinManager.registerActiveWindow(call.arguments["id"]);
      } else if (call.method == kWindowEventHide) {
        await rustDeskWinManager.unregisterActiveWindow(call.arguments['id']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildBlock(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.background.withOpacity(0.8),
            ],
          ),
        ),
        child: buildMainContent(context),
      ),
    );
  }

  Widget _buildBlock({required Widget child}) {
    return buildRemoteBlock(
        block: _block, mask: true, use: canBeBlocked, child: child);
  }

  Widget buildMainContent(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: gFFI.serverModel,
      child: Container(
        width: 400.0,
        child: Stack(
          children: [
            // Background decoration
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blue.withOpacity(0.05),
                      Colors.purple.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
            // Main content
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _leftPaneScrollController,
                    child: Column(
                      key: _childKey,
                      children: [
                        _buildLogo(),
                        _buildWelcomeMessage(),
                        _buildIDBoard(context),
                        _buildPasswordBoard(context),
                        _buildSystemCards(),
                        buildPluginEntry(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Settings button
            _buildSettingsButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                // Logo area
                ScaleTransition(
                  scale: _logoAnimation,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue, Colors.purple],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.computer,
                              color: Colors.white,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Remote Desktop',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              child: ScaleTransition(
                scale: _logoAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/logo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue.shade400,
                                Colors.purple.shade400,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.desktop_windows,
                            color: Colors.white,
                            size: 60,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeMessage() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                Text(
                  'Seu Desktop',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Conecte-se remotamente de qualquer lugar',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIDBoard(BuildContext context) {
    final model = gFFI.serverModel;
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          translate("ID"),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.titleLarge?.color?.withOpacity(0.7),
                          ),
                        ),
                        const Spacer(),
                        buildPopupMenu(context),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onDoubleTap: () {
                        Clipboard.setData(
                            ClipboardData(text: model.serverId.text));
                        showToast(translate("Copied"));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          model.serverId.text.isEmpty ? "Gerando..." : model.serverId.text,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildPopupMenu(BuildContext context) {
    final textColor = Theme.of(context).textTheme.titleLarge?.color;
    RxBool hover = false.obs;
    return InkWell(
      onTap: DesktopTabPage.onAddSetting,
      child: Tooltip(
        message: translate('Settings'),
        child: Obx(
          () => Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: hover.value
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: Icon(
              Icons.settings_outlined,
              size: 20,
              color: hover.value ? Theme.of(context).primaryColor : textColor?.withOpacity(0.5),
            ),
          ),
        ),
      ),
      onHover: (value) => hover.value = value,
    );
  }

  Widget _buildPasswordBoard(BuildContext context) {
    return ChangeNotifierProvider.value(
        value: gFFI.serverModel,
        child: Consumer<ServerModel>(
          builder: (context, model, child) {
            return _buildPasswordBoard2(context, model);
          },
        ));
  }

  Widget _buildPasswordBoard2(BuildContext context, ServerModel model) {
    RxBool refreshHover = false.obs;
    RxBool editHover = false.obs;
    final textColor = Theme.of(context).textTheme.titleLarge?.color;
    final showOneTime = model.approveMode != 'click' &&
        model.verificationMethod != kUsePermanentPassword;
    
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            translate("One-time Password"),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor?.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onDoubleTap: () {
                              if (showOneTime) {
                                Clipboard.setData(
                                    ClipboardData(text: model.serverPasswd.text));
                                showToast(translate("Copied"));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                model.serverPasswd.text.isEmpty ? "Gerando..." : model.serverPasswd.text,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (showOneTime)
                          AnimatedRotationWidget(
                            onPressed: () => bind.mainUpdateTemporaryPassword(),
                            child: Tooltip(
                              message: translate('Refresh Password'),
                              child: Obx(() => Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: refreshHover.value
                                      ? Colors.orange.withOpacity(0.1)
                                      : Colors.transparent,
                                ),
                                child: Icon(
                                  Icons.refresh,
                                  color: refreshHover.value
                                      ? Colors.orange
                                      : textColor?.withOpacity(0.5),
                                  size: 20,
                                ),
                              )),
                            ),
                            onHover: (value) => refreshHover.value = value,
                          ),
                        if (!bind.isDisableSettings())
                          InkWell(
                            child: Tooltip(
                              message: translate('Change Password'),
                              child: Obx(
                                () => Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: editHover.value
                                        ? Colors.orange.withOpacity(0.1)
                                        : Colors.transparent,
                                  ),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    color: editHover.value
                                        ? Colors.orange
                                        : textColor?.withOpacity(0.5),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            onTap: () => DesktopSettingPage.switch2page(
                                SettingsTabKey.safety),
                            onHover: (value) => editHover.value = value,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSystemCards() {
    return FutureBuilder<Widget>(
      future: Future.value(
          Obx(() => buildHelpCards(stateGlobal.updateUrl.value))),
      builder: (_, data) {
        if (data.hasData) {
          return data.data!;
        } else {
          return const Offstage();
        }
      },
    );
  }

  Widget buildHelpCards(String updateUrl) {
    // Remove update notifications completely
    if (systemError.isNotEmpty) {
      return buildInstallCard("Erro", systemError, "", () {});
    }

    if (isWindows && !bind.isDisableInstallation()) {
      if (!bind.mainIsInstalled()) {
        return buildInstallCard(
            "", bind.isOutgoingOnly() ? "" : "install_tip", "Install",
            () async {
          await rustDeskWinManager.closeAllSubWindows();
          bind.mainGotoInstall();
        });
      }
    } else if (isMacOS) {
      final isOutgoingOnly = bind.isOutgoingOnly();
      if (!(isOutgoingOnly || bind.mainIsCanScreenRecording(prompt: false))) {
        return buildInstallCard("Permissões", "config_screen", "Configurar",
            () async {
          bind.mainIsCanScreenRecording(prompt: true);
          watchIsCanScreenRecording = true;
        }, help: 'Ajuda', link: translate("doc_mac_permission"));
      } else if (!isOutgoingOnly && !bind.mainIsProcessTrusted(prompt: false)) {
        return buildInstallCard("Permissões", "config_acc", "Configurar",
            () async {
          bind.mainIsProcessTrusted(prompt: true);
          watchIsProcessTrust = true;
        }, help: 'Ajuda', link: translate("doc_mac_permission"));
      } else if (!bind.mainIsCanInputMonitoring(prompt: false)) {
        return buildInstallCard("Permissões", "config_input", "Configurar",
            () async {
          bind.mainIsCanInputMonitoring(prompt: true);
          watchIsInputMonitoring = true;
        }, help: 'Ajuda', link: translate("doc_mac_permission"));
      } else if (!isOutgoingOnly &&
          !svcStopped.value &&
          bind.mainIsInstalled() &&
          !bind.mainIsInstalledDaemon(prompt: false)) {
        return buildInstallCard("", "install_daemon_tip", "Instalar", () async {
          bind.mainIsInstalledDaemon(prompt: true);
        });
      }
    } else if (isLinux) {
      if (bind.isOutgoingOnly()) {
        return Container();
      }
      final LinuxCards = <Widget>[];
      if (bind.isSelinuxEnforcing()) {
        final keyShowSelinuxHelpTip = "show-selinux-help-tip";
        if (bind.mainGetLocalOption(key: keyShowSelinuxHelpTip) != 'N') {
          LinuxCards.add(buildInstallCard(
            "Aviso",
            "selinux_tip",
            "",
            () async {},
            marginTop: LinuxCards.isEmpty ? 20.0 : 5.0,
            help: 'Ajuda',
            link: 'https://rustdesk.com/docs/en/client/linux/#permissions-issue',
            closeButton: true,
            closeOption: keyShowSelinuxHelpTip,
          ));
        }
      }
      if (bind.mainCurrentIsWayland()) {
        LinuxCards.add(buildInstallCard(
            "Aviso", "wayland_experiment_tip", "", () async {},
            marginTop: LinuxCards.isEmpty ? 20.0 : 5.0,
            help: 'Ajuda',
            link: 'https://rustdesk.com/docs/en/client/linux/#x11-required'));
      } else if (bind.mainIsLoginWayland()) {
        LinuxCards.add(buildInstallCard("Aviso",
            "Login screen using Wayland is not supported", "", () async {},
            marginTop: LinuxCards.isEmpty ? 20.0 : 5.0,
            help: 'Ajuda',
            link: 'https://rustdesk.com/docs/en/client/linux/#login-screen'));
      }
      if (LinuxCards.isNotEmpty) {
        return Column(
          children: LinuxCards,
        );
      }
    }
    if (bind.isIncomingOnly()) {
      return Container(
        margin: const EdgeInsets.all(20),
        child: ElevatedButton.icon(
          onPressed: () {
            SystemNavigator.pop();
            if (isWindows) {
              exit(0);
            }
          },
          icon: const Icon(Icons.exit_to_app),
          label: Text(translate('Quit')),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }
    return Container();
  }

  Widget buildInstallCard(String title, String content, String btnText,
      GestureTapCallback onPressed,
      {double marginTop = 20.0,
      String? help,
      String? link,
      bool? closeButton,
      String? closeOption}) {
    if (bind.mainGetBuildinOption(key: kOptionHideHelpCards) == 'Y' &&
        content != 'install_daemon_tip') {
      return const SizedBox();
    }
    
    void closeCard() async {
      if (closeOption != null) {
        await bind.mainSetLocalOption(key: closeOption, value: 'N');
        if (bind.mainGetLocalOption(key: closeOption) == 'N') {
          setState(() {
            isCardClosed = true;
          });
        }
      } else {
        setState(() {
          isCardClosed = true;
        });
      }
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: EdgeInsets.fromLTRB(20, marginTop, 20, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade400,
                  Colors.purple.shade400,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (title.isNotEmpty
                            ? <Widget>[
                                Text(
                                  translate(title),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ]
                            : <Widget>[]) +
                        <Widget>[
                          if (content.isNotEmpty)
                            Text(
                              translate(content),
                              style: const TextStyle(
                                height: 1.5,
                                color: Colors.white,
                                fontWeight: FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          if (btnText.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton(
                                onPressed: onPressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue.shade600,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  translate(btnText),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (help != null) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: () async => await launchUrl(Uri.parse(link!)),
                                child: Text(
                                  translate(help),
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                  ),
                ),
                if (closeButton == true)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: closeCard,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    final textColor = Theme.of(context).textTheme.titleLarge?.color;
    return Positioned(
      bottom: 20,
      left: 20,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Obx(
              () => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _editHover.value
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.settings_outlined,
                      color: _editHover.value
                          ? Theme.of(context).primaryColor
                          : textColor?.withOpacity(0.7),
                      size: 24,
                    ),
                  ),
                  onTap: () => {
                    if (DesktopSettingPage.tabKeys.isNotEmpty)
                      {
                        DesktopSettingPage.switch2page(
                            DesktopSettingPage.tabKeys[0])
                      }
                  },
                  onHover: (value) => _editHover.value = value,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  _updateWindowSize() {
    RenderObject? renderObject = _childKey.currentContext?.findRenderObject();
    if (renderObject == null) {
      return;
    }
    if (renderObject is RenderBox) {
      final size = renderObject.size;
      if (size != imcomingOnlyHomeSize) {
        imcomingOnlyHomeSize = size;
        windowManager.setSize(getIncomingOnlyHomeSize());
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _logoController.dispose();
    _uniLinksSubscription?.cancel();
    Get.delete<RxBool>(tag: 'stop-service');
    _updateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      shouldBeBlocked(_block, canBeBlocked);
    }
  }

  Widget buildPluginEntry() {
    final entries = PluginUiManager.instance.entries.entries;
    return Offstage(
      offstage: entries.isEmpty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...entries.map((entry) {
            return entry.value;
          })
        ],
      ),
    );
  }
}

void setPasswordDialog({VoidCallback? notEmptyCallback}) async {
  final pw = await bind.mainGetPermanentPassword();
  final p0 = TextEditingController(text: pw);
  final p1 = TextEditingController(text: pw);
  var errMsg0 = "";
  var errMsg1 = "";
  final RxString rxPass = pw.trim().obs;
  final rules = [
    DigitValidationRule(),
    UppercaseValidationRule(),
    LowercaseValidationRule(),
    MinCharactersValidationRule(8),
  ];
  final maxLength = bind.mainMaxEncryptLen();

  gFFI.dialogManager.show((setState, close, context) {
    submit() {
      setState(() {
        errMsg0 = "";
        errMsg1 = "";
      });
      final pass = p0.text.trim();
      if (pass.isNotEmpty) {
        final Iterable violations = rules.where((r) => !r.validate(pass));
        if (violations.isNotEmpty) {
          setState(() {
            errMsg0 =
                '${translate('Prompt')}: ${violations.map((r) => r.name).join(', ')}';
          });
          return;
        }
      }
      if (p1.text.trim() != pass) {
        setState(() {
          errMsg1 =
              '${translate('Prompt')}: ${translate("The confirmation is not identical.")}';
        });
        return;
      }
      bind.mainSetPermanentPassword(password: pass);
      if (pass.isNotEmpty) {
        notEmptyCallback?.call();
      }
      close();
    }

    return CustomAlertDialog(
      title: Text(translate("Set Password")),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                        labelText: translate('Password'),
                        errorText: errMsg0.isNotEmpty ? errMsg0 : null),
                    controller: p0,
                    autofocus: true,
                    onChanged: (value) {
                      rxPass.value = value.trim();
                      setState(() {
                        errMsg0 = '';
                      });
                    },
                    maxLength: maxLength,
                  ).workaroundFreezeLinuxMint(),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: PasswordStrengthIndicator(password: rxPass)),
              ],
            ).marginSymmetric(vertical: 8),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                        labelText: translate('Confirmation'),
                        errorText: errMsg1.isNotEmpty ? errMsg1 : null),
                    controller: p1,
                    onChanged: (value) {
                      setState(() {
                        errMsg1 = '';
                      });
                    },
                    maxLength: maxLength,
                  ).workaroundFreezeLinuxMint(),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Obx(() => Wrap(
                  runSpacing: 8,
                  spacing: 4,
                  children: rules.map((e) {
                    var checked = e.validate(rxPass.value.trim());
                    return Chip(
                        label: Text(
                          e.name,
                          style: TextStyle(
                              color: checked
                                  ? const Color(0xFF0A9471)
                                  : Color.fromARGB(255, 198, 86, 157)),
                        ),
                        backgroundColor: checked
                            ? const Color(0xFFD0F7ED)
                            : Color.fromARGB(255, 247, 205, 232));
                  }).toList(),
                ))
          ],
        ),
      ),
      actions: [
        dialogButton("Cancel", onPressed: close, isOutline: true),
        dialogButton("OK", onPressed: submit),
      ],
      onSubmit: submit,
      onCancel: close,
    );
  });
}
