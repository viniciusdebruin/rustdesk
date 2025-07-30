import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../common.dart';
import '../../models/platform_model.dart';
import '../../models/state_model.dart';
import '../../models/server_model.dart';

// Import necessary files for content pages.
// IMPORTANT: These files (server_page.dart, chat_page.dart, settings_page.dart)
// MUST define their respective classes (EpicServerPageContent, ChatPage, SettingsPage)
// as regular StatelessWidget or StatefulWidget, NOT extending PageShape.
// They should ONLY have a standard build(BuildContext context) method.
// I'm assuming you have these files and their contents are correct now,
// or that the "wrappers" provide placeholder content.
// If not, please provide their full content.
// import 'package:flutter_hbb/mobile/pages/server_page.dart'; // If EpicServerPageContent is defined here
// import 'package:flutter_hbb/common/widgets/chat_page.dart'; // If ChatPage is defined here
// import 'package:flutter_hbb/mobile/pages/settings_page.dart'; // If SettingsPage is defined here

abstract class PageShape extends StatelessWidget {
  const PageShape({Key? key}) : super(key: key); // Add const constructor

  String get title => "";
  Widget get icon => const Icon(null); // Make const
  List<Widget> get appBarActions => const []; // Make const

  Widget buildPage(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return buildPage(context);
  }
}

class HomePage extends StatefulWidget {
  static final homeKey = GlobalKey<HomePageState>();

  HomePage() : super(key: homeKey);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  var _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;
  final List<PageShape> _pages = [];
  int _chatPageTabIndex = -1;
  // Safer check for isAndroid from platform_model
  bool get isChatPageCurrentTab =>
      (isAndroid ?? false) && _selectedIndex == _chatPageTabIndex;

  late AnimationController _logoController;
  late AnimationController _gradientController;
  late Animation<double> _logoAnimation;
  late Animation<double> _gradientAnimation;

  // --- REMOVED: This buildPage method does NOT belong in a State class ---
  // @override
  // Widget buildPage(BuildContext context) {
  //   return build(context);
  // }
  // --------------------------------------------------------------------

  void refreshPages() {
    setState(() {
      initPages();
    });
  }

  @override
  void initState() {
    super.initState();
    initPages();

    _logoController = AnimationController(
      duration: const Duration(seconds: 3), // Make const
      vsync: this,
    );
    _gradientController = AnimationController(
      duration: const Duration(seconds: 4), // Make const
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut),
    );

    _logoController.repeat(reverse: true);
    _gradientController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  void initPages() {
    _pages.clear();
    _pages.add(const EpicServerPage()); // Use const for PageShape instances

    try {
      if (isAndroid ?? false) {
        // Safer check
        _chatPageTabIndex = _pages.length;
        _pages.add(const ChatPageWrapper()); // Use const
      }
    } catch (e) {
      debugPrint("Chat não disponível: $e"); // Use debugPrint for Flutter logs
    }

    _pages.add(const SettingsPageWrapper()); // Use const
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Use PopScope instead of WillPopScope for modern Flutter
      canPop:
          _selectedIndex ==
          0, // This replaces the old onWillPop logic for canPop
      onPopInvoked: (bool didPop) {
        if (didPop) return; // If pop happened, nothing more to do
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF667eea).withOpacity(
                      0.1 + _gradientAnimation.value * 0.05,
                    ), // Make const
                    const Color(0xFF764ba2).withOpacity(
                      0.1 + _gradientAnimation.value * 0.05,
                    ), // Make const
                    const Color(0xFF2F65BA).withOpacity(
                      0.05 + _gradientAnimation.value * 0.03,
                    ), // Make const
                  ],
                ),
              ),
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: _buildEpicAppBar(context),
                bottomNavigationBar: _buildEpicBottomNav(),
                body:
                    _pages.isNotEmpty
                        ? _pages.elementAt(_selectedIndex)
                        : Container(),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildEpicAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            // Make const
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(
                0xFF2F65BA,
              ), // Removed opacity here for AppBar background solidity
              Color(0xFF667eea),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2F65BA).withOpacity(0.3), // Make const
              blurRadius: 10,
              offset: const Offset(0, 3), // Make const
            ),
          ],
        ),
      ),
      centerTitle: true,
      title: AnimatedBuilder(
        animation: _logoController,
        builder: (context, child) {
          return Transform.scale(
            scale: _logoAnimation.value,
            child: appTitle(),
          );
        },
      ),
      actions:
          _pages.isNotEmpty
              ? _pages.elementAt(_selectedIndex).appBarActions
              : const [], // Make const
    );
  }

  Widget _buildEpicBottomNav() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          // Make const
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2F65BA), // Removed opacity for bottom nav solidity
            Color(0xFF667eea),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F65BA).withOpacity(0.3), // Make const
            blurRadius: 15,
            offset: const Offset(0, -5), // Make const
          ),
        ],
      ),
      child: BottomNavigationBar(
        key:
            navigationBarKey, // Assumindo que navigationBarKey está definido em 'common.dart' ou similar
        backgroundColor: Colors.transparent,
        elevation: 0,
        items:
            _pages
                .map(
                  (page) => BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(8), // Make const
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color:
                            _pages.indexOf(page) == _selectedIndex
                                ? Colors.white.withOpacity(0.2)
                                : Colors.transparent,
                      ),
                      child: page.icon,
                    ),
                    label: page.title,
                  ),
                )
                .toList(),
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        selectedLabelStyle: const TextStyle(
          // Make const
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          // Make const
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        onTap:
            (index) => setState(() {
              if (_selectedIndex != index) {
                _selectedIndex = index;
                if (isChatPageCurrentTab) {
                  try {
                    // Assumindo que gFFI.chatModel e suas funções estão disponíveis
                    gFFI.chatModel.hideChatIconOverlay();
                    gFFI.chatModel.hideChatWindowOverlay();
                    gFFI.chatModel.mobileClearClientUnread(
                      gFFI.chatModel.currentKey.connId,
                    );
                  } catch (e) {
                    debugPrint("Erro ao gerenciar chat: $e"); // Use debugPrint
                  }
                }
              }
            }),
      ),
    );
  }

  Widget appTitle() {
    try {
      final currentUser = gFFI.chatModel.currentUser;
      final currentKey = gFFI.chatModel.currentKey;
      if (isChatPageCurrentTab &&
          currentUser != null &&
          currentKey.peerId.isNotEmpty) {
        final connected = gFFI.serverModel.clients.any(
          (e) => e.id == currentKey.connId,
        );
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Tooltip(
              message:
                  currentKey.isOut
                      ? translate('Outgoing connection')
                      : translate('Incoming connection'),
              child: Icon(
                currentKey.isOut
                    ? Icons.call_made_rounded
                    : Icons.call_received_rounded,
                color: Colors.white,
              ),
            ),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${currentUser.firstName}   ${currentUser.id}",
                      style: const TextStyle(color: Colors.white), // Make const
                    ),
                    if (connected)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          // Make const
                          shape: BoxShape.circle,
                          color: Color.fromARGB(255, 133, 246, 199),
                        ),
                      ).marginSymmetric(horizontal: 2),
                  ],
                ),
              ),
            ),
          ],
        );
      }
    } catch (e) {
      debugPrint("Erro ao obter informações do chat: $e"); // Use debugPrint
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              // Make const
              BoxShadow(
                color:
                    Colors
                        .white, // Changed from withOpacity for better visibility of shadow color
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/debruin_remote_access_logo.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12), // Make const
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              // Make const
              'deBruin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'SISTEMAS',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class EpicServerPage extends PageShape {
  const EpicServerPage({Key? key}) : super(key: key); // Add const constructor

  @override
  String get title => "deBruin Server";

  @override
  Widget get icon => const Icon(Icons.security_rounded); // Make const

  @override
  List<Widget> get appBarActions => const []; // Make const

  @override
  Widget buildPage(BuildContext context) {
    return const EpicServerPageContent(); // Use const
  }
}

class ChatPageWrapper extends PageShape {
  const ChatPageWrapper({Key? key}) : super(key: key); // Add const constructor

  @override
  String get title => "Chat";

  @override
  Widget get icon => const Icon(Icons.chat); // Make const

  @override
  List<Widget> get appBarActions => const []; // Make const

  @override
  Widget buildPage(BuildContext context) {
    // This is a placeholder. If you have a real ChatPage widget,
    // import it and return it here instead.
    // Example: return const ChatPage(type: ChatPageType.mobileMain);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20), // Make const
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.chat,
                size: 64,
                color: Color(0xFF2F65BA),
              ), // Make const
              const SizedBox(height: 20), // Make const
              const Text(
                // Make const
                'Chat deBruin SISTEMAS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F65BA),
                ),
              ),
              const SizedBox(height: 10), // Make const
              const Text(
                // Make const
                'Funcionalidade de chat em desenvolvimento',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ), // Simplified color
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPageWrapper extends PageShape {
  const SettingsPageWrapper({Key? key})
    : super(key: key); // Add const constructor

  @override
  String get title => "Configurações";

  @override
  Widget get icon => const Icon(Icons.settings); // Make const

  @override
  List<Widget> get appBarActions => const []; // Make const

  @override
  Widget buildPage(BuildContext context) {
    // This is a placeholder. If you have a real SettingsPage widget,
    // import it and return it here instead.
    // Example: return const SettingsPage();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20), // Make const
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.settings,
                size: 64,
                color: Color(0xFF2F65BA),
              ), // Make const
              const SizedBox(height: 20), // Make const
              const Text(
                // Make const
                'Configurações deBruin SISTEMAS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F65BA),
                ),
              ),
              const SizedBox(height: 10), // Make const
              const Text(
                // Make const
                'Configurações em desenvolvimento',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ), // Simplified color
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// This is the actual content for the server page.
// It is a StatefulWidget and thus manages its own state and lifecycle.
// It should NOT extend PageShape.
class EpicServerPageContent extends StatefulWidget {
  const EpicServerPageContent({Key? key})
    : super(key: key); // Add const constructor

  @override
  _EpicServerPageContentState createState() => _EpicServerPageContentState();
}

class _EpicServerPageContentState extends State<EpicServerPageContent>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // --- REMOVED: This buildPage method does NOT belong in a State class ---
  // @override
  // Widget buildPage(BuildContext context) {
  //   return build(context);
  // }
  // --------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2), // Make const
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    // Assuming that gFFI.serverModel and bind.mainUpdateTemporaryPassword()
    // are accessible and correctly configured in your project.
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ChangeNotifierProvider.value(
        value: gFFI.serverModel, // Assuming gFFI.serverModel is available
        child: Consumer<ServerModel>(
          builder: (context, model, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20), // Make const
                child: Column(
                  children: [
                    const SizedBox(height: 20), // Make const
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(
                                    0xFF667eea,
                                  ).withOpacity(0.3), // Make const
                                  const Color(
                                    0xFF764ba2,
                                  ).withOpacity(0.3), // Make const
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2F65BA,
                                  ).withOpacity(0.4), // Make const
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 50,
                                  spreadRadius: 10,
                                ),
                              ],
                              border: Border.all(
                                color: const Color(
                                  0xFF2F65BA,
                                ).withOpacity(0.3), // Make const
                                width: 3,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/images/debruin_remote_access_logo.jpg',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30), // Make const
                    Text(
                      'deBruin SISTEMAS',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        foreground:
                            Paint()
                              ..shader = const LinearGradient(
                                // Make const
                                colors: [Color(0xFF2F65BA), Color(0xFF667eea)],
                              ).createShader(
                                const Rect.fromLTWH(
                                  0.0,
                                  0.0,
                                  200.0,
                                  70.0,
                                ), // Make const
                              ),
                        letterSpacing: 2.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10), // Make const
                    const Text(
                      // Make const
                      'Acesso Remoto Profissional',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF667eea),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30), // Make const
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 5,
                      ), // Make const
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(
                              0xFF4CAF50,
                            ).withOpacity(0.1), // Make const
                            const Color(
                              0xFF8BC34A,
                            ).withOpacity(0.1), // Make const
                          ],
                        ),
                        border: Border.all(
                          color: const Color(
                            0xFF4CAF50,
                          ).withOpacity(0.3), // Make const
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF4CAF50,
                            ).withOpacity(0.1), // Make const
                            blurRadius: 15,
                            offset: const Offset(0, 8), // Make const
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20), // Make const
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12), // Make const
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50), // Make const
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                // Make const
                                Icons.security,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 15), // Make const
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    // Make const
                                    'Servidor Ativo',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                  const Text(
                                    // Make const
                                    'Aguardando conexões remotas...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey, // Simplified color
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                // Make const
                                shape: BoxShape.circle,
                                color: Colors.green,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green, // Simplified color
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25), // Make const
                    _buildIDCard(context, model),
                    const SizedBox(height: 25), // Make const
                    _buildPasswordCard(context, model),
                    const SizedBox(height: 30), // Make const
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 5,
                      ), // Make const
                      padding: const EdgeInsets.all(20), // Make const
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          colors: [
                            const Color(
                              0xFF667eea,
                            ).withOpacity(0.1), // Make const
                            const Color(
                              0xFF764ba2,
                            ).withOpacity(0.1), // Make const
                          ],
                        ),
                        border: Border.all(
                          color: const Color(
                            0xFF667eea,
                          ).withOpacity(0.3), // Make const
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            // Make const
                            Icons.info_outline,
                            color: Color(0xFF667eea),
                            size: 24,
                          ),
                          const SizedBox(width: 12), // Make const
                          Expanded(
                            child: const Text(
                              // Make const
                              'Este dispositivo está configurado para receber conexões remotas da deBruin SISTEMAS.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF667eea),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIDCard(BuildContext context, ServerModel model) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5), // Make const
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667eea).withOpacity(0.1), // Make const
            const Color(0xFF764ba2).withOpacity(0.1), // Make const
          ],
        ),
        border: Border.all(
          color: const Color(0xFF2F65BA).withOpacity(0.3),
          width: 2,
        ), // Make const
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F65BA).withOpacity(0.1), // Make const
            blurRadius: 15,
            offset: const Offset(0, 8), // Make const
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(25), // Make const
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12), // Make const
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F65BA), // Make const
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.computer,
                    color: Colors.white,
                    size: 24,
                  ), // Make const
                ),
                const SizedBox(width: 15), // Make const
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        // Make const
                        'ID do Dispositivo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2F65BA),
                        ),
                      ),
                      const Text(
                        // Make const
                        'Toque para copiar',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ), // Simplified color
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20), // Make const
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: model.serverId.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    // Make const
                    content: Text('ID copiado para a área de transferência'),
                    backgroundColor: Color(0xFF4CAF50),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ), // Make const
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFF2F65BA).withOpacity(0.2),
                  ), // Make const
                ),
                child: Text(
                  model.serverId.text.isNotEmpty
                      ? model.serverId.text
                      : 'Carregando...',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard(BuildContext context, ServerModel model) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5), // Make const
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFf093fb).withOpacity(0.1), // Make const
            const Color(0xFFf5576c).withOpacity(0.1), // Make const
          ],
        ),
        border: Border.all(
          color: const Color(0xFFf5576c).withOpacity(0.3),
          width: 2,
        ), // Make const
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFf5576c).withOpacity(0.1), // Make const
            blurRadius: 15,
            offset: const Offset(0, 8), // Make const
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(25), // Make const
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12), // Make const
                  decoration: BoxDecoration(
                    color: const Color(0xFFf5576c), // Make const
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 24,
                  ), // Make const
                ),
                const SizedBox(width: 15), // Make const
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        // Make const
                        'Senha de Acesso',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFf5576c),
                        ),
                      ),
                      const Text(
                        // Make const
                        'Toque para copiar',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ), // Simplified color
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => bind.mainUpdateTemporaryPassword(),
                  child: Container(
                    padding: const EdgeInsets.all(8), // Make const
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFf5576c,
                      ).withOpacity(0.1), // Make const
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      // Make const
                      Icons.refresh,
                      color: Color(0xFFf5576c),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20), // Make const
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: model.serverPasswd.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    // Make const
                    content: Text('Senha copiada para a área de transferência'),
                    backgroundColor: Color(0xFFf5576c),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ), // Make const
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFf5576c).withOpacity(0.2),
                  ), // Make const
                ),
                child: Text(
                  model.serverPasswd.text.isNotEmpty
                      ? model.serverPasswd.text
                      : 'Carregando...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WebHomePage extends PageShape {
  const WebHomePage({Key? key}) : super(key: key); // Add const constructor

  @override
  String get title => "Web Home";

  @override
  Widget get icon => const Icon(Icons.web); // Make const

  @override
  List<Widget> get appBarActions => [
    IconButton(
      icon: const Icon(Icons.settings), // Make const
      onPressed: () {
        // Ação de configurações.
        // Se você tiver uma rota ou método para abrir configurações web, chame aqui.
        // Ex: Get.to(() => const WebSettingsPage()); // requires GetX
      },
    ),
  ];

  @override
  Widget buildPage(BuildContext context) {
    // Moved try-catch to where stateGlobal is actually used if it might be null
    // or not initialized. Assumes stateGlobal is defined elsewhere.
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  // Make const
                  BoxShadow(
                    color: Colors.white, // Simplified shadow color
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/debruin_remote_access_logo.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10), // Make const
            const Text("deBruin SISTEMAS - Web Server"), // Make const
          ],
        ),
        actions: appBarActions, // Use the getter here
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600), // Make const
          padding: const EdgeInsets.all(20), // Make const
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF667eea).withOpacity(0.2), // Make const
                      const Color(0xFF764ba2).withOpacity(0.2), // Make const
                    ],
                  ),
                  border: Border.all(
                    color: const Color(
                      0xFF2F65BA,
                    ).withOpacity(0.3), // Make const
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15), // Make const
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      'assets/images/debruin_remote_access_logo.jpg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30), // Make const
              const Text(
                // Make const
                'deBruin SISTEMAS',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F65BA),
                ),
              ),
              const SizedBox(height: 10), // Make const
              const Text(
                // Make const
                'Servidor Web - Acesso Remoto',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF667eea),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40), // Make const
              Container(
                padding: const EdgeInsets.all(25), // Make const
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4CAF50).withOpacity(0.1), // Make const
                      const Color(0xFF8BC34A).withOpacity(0.1), // Make const
                    ],
                  ),
                  border: Border.all(
                    color: const Color(
                      0xFF4CAF50,
                    ).withOpacity(0.3), // Make const
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          // Make const
                          Icons.security,
                          color: Color(0xFF4CAF50),
                          size: 28,
                        ),
                        const SizedBox(width: 12), // Make const
                        const Text(
                          // Make const
                          'Servidor Ativo',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20), // Make const
                    const Text(
                      // Make const
                      'Este é o servidor web da deBruin SISTEMAS. Para acesso remoto completo, utilize nosso aplicativo dedicado.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ), // Simplified color
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
