import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../common.dart';
import '../../models/platform_model.dart';
import '../../models/state_model.dart';
import '../../models/server_model.dart';
// Importe as páginas reais aqui. Se elas não existirem, use os Wrappers como placeholders.
// import 'package:flutter_hbb/mobile/pages/server_page.dart';
// import 'package:flutter_hbb/common/widgets/chat_page.dart';
// import 'package:flutter_hbb/mobile/pages/settings_page.dart';
// import 'package:flutter_hbb/web/settings_page.dart'; // Para WebHomePage

// Chave global para o BottomNavigationBar
final GlobalKey navigationBarKey = GlobalKey();

// A classe abstrata PageShape que define a interface para as páginas do BottomNavigationBar
abstract class PageShape extends StatelessWidget {
  const PageShape({Key? key}) : super(key: key);

  String get title;
  Widget get icon;
  List<Widget> get appBarActions;

  // Este método será implementado pelas classes concretas que estendem PageShape
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
  bool get isChatPageCurrentTab =>
      (isAndroid ?? false) && _selectedIndex == _chatPageTabIndex;

  late AnimationController _logoController;
  late AnimationController _gradientController;
  late Animation<double> _logoAnimation;
  late Animation<double> _gradientAnimation;

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
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _gradientController = AnimationController(
      duration: const Duration(seconds: 4),
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

    // Adicione as páginas usando os Wrappers
    _pages.add(const EpicServerPage());

    if (isAndroid ?? false) {
      _chatPageTabIndex = _pages.length;
      _pages.add(const ChatPageWrapper()); // Usando o Wrapper
    }

    _pages.add(const SettingsPageWrapper()); // Usando o Wrapper

    // Se você tiver uma página web, adicione-a aqui
    // _pages.add(const WebHomePage());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvoked: (bool didPop) {
        if (didPop) return;
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
                    const Color(
                      0xFF667eea,
                    ).withOpacity(0.1 + _gradientAnimation.value * 0.05),
                    const Color(
                      0xFF764ba2,
                    ).withOpacity(0.1 + _gradientAnimation.value * 0.05),
                    const Color(
                      0xFF2F65BA,
                    ).withOpacity(0.05 + _gradientAnimation.value * 0.03),
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2F65BA), Color(0xFF667eea)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2F65BA).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
              : const [],
    );
  }

  Widget _buildEpicBottomNav() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F65BA), Color(0xFF667eea)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F65BA).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        key: navigationBarKey,
        backgroundColor: Colors.transparent,
        elevation: 0,
        items:
            _pages
                .map(
                  (page) => BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
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
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        onTap:
            (index) => setState(() {
              if (_selectedIndex != index) {
                _selectedIndex = index;
                if (isChatPageCurrentTab) {
                  try {
                    gFFI.chatModel.hideChatIconOverlay();
                    gFFI.chatModel.hideChatWindowOverlay();
                    gFFI.chatModel.mobileClearClientUnread(
                      gFFI.chatModel.currentKey.connId,
                    );
                  } catch (e) {
                    debugPrint("Erro ao gerenciar chat: $e");
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
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (connected)
                      Padding(
                        // Substituído marginSymmetric por Padding
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.fromARGB(255, 133, 246, 199),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }
    } catch (e) {
      debugPrint("Erro ao obter informações do chat: $e");
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
              BoxShadow(color: Colors.white, blurRadius: 8, spreadRadius: 2),
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
        const SizedBox(width: 12),
        const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
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
                color: Colors.white, // Removido opacity para const
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

// Wrapper para a EpicServerPageContent
class EpicServerPage extends PageShape {
  const EpicServerPage({Key? key}) : super(key: key);

  @override
  String get title => "deBruin Server";

  @override
  Widget get icon => const Icon(Icons.security_rounded);

  @override
  List<Widget> get appBarActions => const [];

  @override
  Widget buildPage(BuildContext context) {
    return const EpicServerPageContent();
  }
}

// Wrapper para a ChatPage
class ChatPageWrapper extends PageShape {
  const ChatPageWrapper({Key? key}) : super(key: key);

  @override
  String get title => "Chat";

  @override
  Widget get icon => const Icon(Icons.chat);

  @override
  List<Widget> get appBarActions => const [];

  @override
  Widget buildPage(BuildContext context) {
    // Aqui você deve retornar a sua ChatPage real, se ela existir.
    // Ex: return ChatPage(type: ChatPageType.mobileMain);
    // Por enquanto, é um placeholder:
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat, size: 64, color: Color(0xFF2F65BA)),
              SizedBox(height: 20),
              Text(
                'Chat deBruin SISTEMAS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F65BA),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Funcionalidade de chat em desenvolvimento',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Wrapper para a SettingsPage
class SettingsPageWrapper extends PageShape {
  const SettingsPageWrapper({Key? key}) : super(key: key);

  @override
  String get title => "Configurações";

  @override
  Widget get icon => const Icon(Icons.settings);

  @override
  List<Widget> get appBarActions => const [];

  @override
  Widget buildPage(BuildContext context) {
    // Aqui você deve retornar a sua SettingsPage real, se ela existir.
    // Ex: return SettingsPage();
    // Por enquanto, é um placeholder:
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.settings, size: 64, color: Color(0xFF2F65BA)),
              SizedBox(height: 20),
              Text(
                'Configurações deBruin SISTEMAS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F65BA),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Configurações em desenvolvimento',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// A classe EpicServerPageContent (o conteúdo real da página do servidor)
// Não implementa PageShape, apenas é um StatefulWidget normal.
class EpicServerPageContent extends StatefulWidget {
  const EpicServerPageContent({Key? key}) : super(key: key);

  @override
  _EpicServerPageContentState createState() => _EpicServerPageContentState();
}

class _EpicServerPageContentState extends State<EpicServerPageContent>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
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
        value: gFFI.serverModel,
        child: Consumer<ServerModel>(
          builder: (context, model, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
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
                                  const Color(0xFF667eea).withOpacity(0.3),
                                  const Color(0xFF764ba2).withOpacity(0.3),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2F65BA,
                                  ).withOpacity(0.4),
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
                                color: const Color(0xFF2F65BA).withOpacity(0.3),
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
                    const SizedBox(height: 30),
                    Text(
                      'deBruin SISTEMAS',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        foreground:
                            Paint()
                              ..shader = const LinearGradient(
                                colors: [Color(0xFF2F65BA), Color(0xFF667eea)],
                              ).createShader(
                                const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                              ),
                        letterSpacing: 2.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Acesso Remoto Profissional',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF667eea),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF4CAF50).withOpacity(0.1),
                            const Color(0xFF8BC34A).withOpacity(0.1),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.security,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 15),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Servidor Ativo',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                  Text(
                                    'Aguardando conexões remotas...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green,
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
                    const SizedBox(height: 25),
                    _buildIDCard(context, model),
                    const SizedBox(height: 25),
                    _buildPasswordCard(context, model),
                    const SizedBox(height: 30),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF667eea).withOpacity(0.1),
                            const Color(0xFF764ba2).withOpacity(0.1),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF667eea).withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF667eea),
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
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
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667eea).withOpacity(0.1),
            const Color(0xFF764ba2).withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF2F65BA).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F65BA).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F65BA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.computer,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID do Dispositivo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2F65BA),
                        ),
                      ),
                      Text(
                        'Toque para copiar',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: model.serverId.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
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
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFF2F65BA).withOpacity(0.2),
                  ),
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
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFf093fb).withOpacity(0.1),
            const Color(0xFFf5576c).withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFf5576c).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFf5576c).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf5576c),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Senha de Acesso',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFf5576c),
                        ),
                      ),
                      Text(
                        'Toque para copiar',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => bind.mainUpdateTemporaryPassword(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf5576c).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: Color(0xFFf5576c),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: model.serverPasswd.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
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
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFf5576c).withOpacity(0.2),
                  ),
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

// Classe para a Home Page Web
class WebHomePage extends PageShape {
  const WebHomePage({Key? key}) : super(key: key);

  @override
  String get title => "Web Home";

  @override
  Widget get icon => const Icon(Icons.web);

  @override
  List<Widget> get appBarActions => [
    IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () {
        // Ação de configurações.
        // Se você tiver uma rota ou método para abrir configurações web, chame aqui.
        // Ex: Get.to(() => const WebSettingsPage());
      },
    ),
  ];

  @override
  Widget buildPage(BuildContext context) {
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
                  BoxShadow(
                    color: Colors.white,
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
            const SizedBox(width: 10),
            const Text("deBruin SISTEMAS - Web Server"),
          ],
        ),
        actions: appBarActions,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(20),
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
                      const Color(0xFF667eea).withOpacity(0.2),
                      const Color(0xFF764ba2).withOpacity(0.2),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF2F65BA).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      'assets/images/debruin_remote_access_logo.jpg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'deBruin SISTEMAS',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F65BA),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Servidor Web - Acesso Remoto',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF667eea),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4CAF50).withOpacity(0.1),
                      const Color(0xFF8BC34A).withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.security,
                          color: Color(0xFF4CAF50),
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Servidor Ativo',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Este é o servidor web da deBruin SISTEMAS. Para acesso remoto completo, utilize nosso aplicativo dedicado.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
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
