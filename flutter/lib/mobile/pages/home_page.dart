// Importações comuns e específicas do projeto
import 'dart:async';
import 'dart:io'; // Para exit(0)
import 'dart:convert'; // Para jsonEncode

import 'package:flutter/foundation.dart'; // Para kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart'; // Necessário para Obx, RxBool, .obs, .margin*
import 'package:url_launcher/url_launcher.dart'; // Para launchUrl

// Importações específicas do projeto flutter_hbb
import '../../common.dart'; // Contém showToast, translate, gFFI, bind, etc.
import '../../common/widgets/animated_rotation_widget.dart'; // Se usado em ServerPageContent
import '../../common/widgets/custom_password.dart'; // Se usado em setPasswordDialog, PasswordStrengthIndicator, CustomAlertDialog
import '../../common/widgets/chat_page.dart'; // Para ChatPage
import '../../models/platform_model.dart'; // Para isWindows, isMacOS, isLinux, osxCanRecordAudio, PermissionAuthorizeType
import '../../models/server_model.dart'; // Para gFFI.serverModel
import '../../models/state_model.dart'; // Para stateGlobal, isInHomePage, imcomingOnlyHomeSize, getIncomingOnlyHomeSize
import '../../consts.dart'; // Para kOptionStopService, kUsePermanentPassword, kOptionHideHelpCards (se usados)
import '../widgets/button.dart'; // Para dialogButton (se usado no setPasswordDialog)

// Desktop-specific imports that might not be used in mobile/web, but kept for reference
// import 'package:flutter_hbb/desktop/pages/connection_page.dart';
// import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
// import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart';
// import 'package:flutter_hbb/desktop/widgets/update_progress.dart';
// import 'package:flutter_hbb/utils/multi_window_manager.dart';
// import 'package:window_manager/window_manager.dart';
// import 'package:window_size/window_size.dart' as window_size;

// Definições de cores personalizadas (mantidas do seu `desktop_home_page.dart` anterior)
const Color kDeBruinPrimaryBlue = Color(0xFF2F65BA);
const Color kDeBruinAccentGreen = Color(0xFF4CAF50);
const Color kDeBruinAccentRed = Color(0xFFf5576c);
const Color kDeBruinSubTitleColor = Color(0xFF667eea); // Usada no subtítulo

// A abstração PageShape do seu `origianl.dart`
abstract class PageShape extends Widget {
  final String title;
  final Widget icon;
  final List<Widget> appBarActions;

  // Adicionado construtor para inicializar campos finais
  const PageShape({
    Key? key,
    this.title = "",
    this.icon = const Icon(null),
    this.appBarActions = const [],
  }) : super(key: key);
}

class HomePage extends StatefulWidget {
  static final homeKey =
      GlobalKey<_HomePageState>(); // Corrigido para _HomePageState

  HomePage() : super(key: homeKey);

  @override
  _HomePageState createState() => _HomePageState(); // Corrigido para _HomePageState
}

class _HomePageState extends State<HomePage> {
  // Corrigido para _HomePageState
  var _selectedIndex = 0;
  // int get selectedIndex => _selectedIndex; // Getter não estritamente necessário aqui
  final List<PageShape> _pages = []; // Usando PageShape
  int _chatPageTabIndex = -1; // Mantido do original para lógica de chat
  bool
  get isChatPageCurrentTab => // Lógica do chat page, depende de `isAndroid`
      isAndroid ? _selectedIndex == _chatPageTabIndex : false;

  void refreshPages() {
    setState(() {
      initPages();
    });
  }

  @override
  void initState() {
    super.initState();
    initPages();

    // Lógica de atualização do servidor (copiada do DesktopHomePage)
    // Assegura que gFFI e bind estejam inicializados no ambiente mobile/web
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      await gFFI.serverModel.fetchID();
      final error = await bind.mainGetError();
      if (systemError != error) {
        // systemError é uma variável do _DesktopHomePageState, vamos adicioná-la aqui.
        setState(() {
          systemError = error;
        });
      }
      final v = await mainGetBoolOption(
        kOptionStopService,
      ); // kOptionStopService de consts.dart
      if (v != svcStopped.value) {
        // svcStopped é um RxBool, vamos adicioná-lo aqui.
        setState(() {
          svcStopped.value = v;
        });
      }
      // Adicione aqui outras lógicas de watchIsCanScreenRecording, etc., se aplicáveis ao mobile
      // Para simplicidade, apenas o systemError e svcStopped serão monitorados no mobile.
    });

    // Se você usa GetX, é comum inicializar o RxBool no initState ou na declaração
    // Get.put<RxBool>(svcStopped, tag: 'stop-service'); // Se svcStopped for um RxBool que precisa ser registrado globalmente
  }

  // Variáveis para a lógica do Timer e Status (do DesktopHomePage)
  var systemError = '';
  var svcStopped = false.obs; // GetX RxBool

  @override
  void dispose() {
    // Cancela o timer quando o widget é descartado
    _updateTimer?.cancel(); // _updateTimer precisa ser inicializado
    // Get.delete<RxBool>(tag: 'stop-service'); // Se você registrou globalmente
    super.dispose();
  }

  // initPages ajustado para suas personalizações
  void initPages() {
    _pages.clear();
    // Remover ConnectionPage se o objetivo é "só exibir o ID" e não conectar a outros
    // if (!bind.isIncomingOnly()) {
    //   _pages.add(ConnectionPage(appBarActions: []));
    // }
    // A página principal do servidor agora será `ServerPageContent` personalizada.
    _pages.add(
      ServerPageContent(systemError: systemError, svcStopped: svcStopped),
    ); // Passa o estado

    if (isAndroid && !bind.isOutgoingOnly()) {
      // isAndroid, bind.isOutgoingOnly() precisam ser definidos/importados
      _chatPageTabIndex = _pages.length;
      _pages.addAll([
        ChatPage(
          type: ChatPageType.mobileMain,
        ), // ChatPage, ChatPageType de common/widgets/chat_page.dart
        ServerPage(), // Esta parece ser uma ServerPage antiga, a nova é ServerPageContent
      ]);
    } else {
      // Se não for Android ou for outgoingOnly, talvez você queira manter uma ServerPage aqui
      // para o caso desktop/web onde a ConnectionPage foi removida mas ainda precisa do ServerPage.
      // Vou manter a ServerPageContent personalizada.
    }
    // settingsPage agora também pode ser uma SettingsPageContent customizada se você tiver.
    _pages.add(SettingsPageContent()); // SettingsPageContent customizada
  }

  @override
  Widget build(BuildContext context) {
    // Re-chama initPages para atualizar systemError e svcStopped nas páginas filhas.
    // Isso pode ter implicações de performance se a lista de páginas for grande
    // ou se o initPages for custoso. Alternativa: usar Provider/GetX para systemError/svcStopped
    // e os widgets ServerPageContent, ChatPageContent, SettingsPageContent
    // escutarem as mudanças diretamente.
    initPages(); // Mantido para que as páginas internas recebam o estado atualizado.

    return PopScope(
      // Substitui WillPopScope para Flutter 3.12+
      canPop: _selectedIndex == 0, // Permite voltar se estiver na primeira aba
      onPopInvoked: (bool didPop) {
        if (didPop) return; // Se o pop já ocorreu, não faça nada
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0; // Volta para a primeira aba
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50], // Cor de fundo do Scaffold
        appBar: AppBar(
          backgroundColor: kDeBruinPrimaryBlue, // Cor personalizada
          elevation: 2,
          centerTitle: true,
          title: appTitle(), // Título customizado do AppBar
          // Se as páginas tiverem ações de AppBar, elas serão exibidas
          actions: _pages.elementAt(_selectedIndex).appBarActions,
        ),
        bottomNavigationBar: BottomNavigationBar(
          // key: navigationBarKey, // navigationBarKey não está definido. Removido ou defina.
          items:
              _pages
                  .map(
                    (page) => BottomNavigationBarItem(
                      icon: page.icon,
                      label: page.title,
                    ),
                  )
                  .toList(),
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed, // fixed para mais de 3 itens
          selectedItemColor: Colors.white, // Item selecionado branco
          unselectedItemColor: Colors.white.withOpacity(
            0.6,
          ), // Itens não selecionados mais claros
          onTap:
              (index) => setState(() {
                if (_selectedIndex != index) {
                  _selectedIndex = index;
                  if (isChatPageCurrentTab) {
                    // isChatPageCurrentTab depende da lógica do chat
                    gFFI.chatModel
                        .hideChatIconOverlay(); // gFFI.chatModel precisa ser definido/importado
                    gFFI.chatModel.hideChatWindowOverlay();
                    gFFI.chatModel.mobileClearClientUnread(
                      gFFI.chatModel.currentKey.connId,
                    );
                  }
                }
              }),
        ),
        body: IndexedStack(index: _selectedIndex, children: _pages),
      ),
    );
  }

  // appTitle customizado para exibir o nome da empresa ou detalhes do chat
  Widget appTitle() {
    // Lógica do chat (mantida do original.dart)
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
            ),
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${currentUser.firstName}   ${currentUser.id}"),
                  if (connected)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromARGB(255, 133, 246, 199),
                      ),
                    ).marginSymmetric(
                      horizontal: 2,
                    ), // .marginSymmetric() é do GetX
                ],
              ),
            ),
          ),
        ],
      );
    }
    // Título padrão para a empresa (Personalizado)
    return Text(
      'deBruin SISTEMAS',
    ); // Ou bind.mainGetAppNameSync() se quiser o nome do app
  }
}

// ====================================================================================================
// Conteúdo das Páginas da BottomNavigationBar (Personalizadas)
// ====================================================================================================

// ServerPageContent (Substitui o ServerPage e incorpora as personalizações do DesktopHomePage)
class ServerPageContent extends PageShape {
  final String systemError;
  final RxBool svcStopped; // RxBool para o estado do serviço

  const ServerPageContent({
    Key? key,
    this.systemError = '',
    required this.svcStopped, // Marcado como required
  }) : super(
         key: key,
         title: 'Servidor',
         icon: const Icon(Icons.security), // Ícone do servidor
         appBarActions:
             const [], // Sem ações específicas no AppBar para esta página
       );

  // Funções de construção de widgets internos (adaptadas do DesktopHomePage)
  // Essas funções agora são MÉTODOS desta classe ServerPageContent
  Widget _buildIDBoard(BuildContext context, ServerModel model) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        border: Border.all(
          color: kDeBruinPrimaryBlue.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kDeBruinPrimaryBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.computer,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      translate("ID"),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kDeBruinPrimaryBlue,
                      ),
                    ),
                  ],
                ),
                // buildPopupMenu(context), // Removido para o layout simplificado
              ],
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onDoubleTap: () {
                Clipboard.setData(ClipboardData(text: model.serverId.text));
                showToast(translate("Copied"));
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  model.serverId.text.isNotEmpty
                      ? model.serverId.text
                      : 'Carregando ID...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
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

  // O card de senha (_buildPasswordBoard) foi removido completamente da UI para focar apenas no ID.
  // Widget _buildPasswordBoard(BuildContext context, ServerModel model) { /* ... */ }

  // buildHelpCards adaptado (agora é um método de ServerPageContent)
  Widget _buildHelpCards(String updateUrl, BuildContext context) {
    if (systemError.isNotEmpty) {
      return _buildInstallCard(
        // Chame o método interno
        "",
        systemError,
        "",
        () {},
        cardColor: kDeBruinAccentRed.withOpacity(0.1),
        borderColor: kDeBruinAccentRed.withOpacity(0.3),
        textColor: kDeBruinAccentRed,
        isSystemError:
            true, // Adiciona um flag para estilo ou lógica específica de erro de sistema
      );
    }
    // Lógica para Windows
    if (isWindows && !bind.isDisableInstallation()) {
      // isWindows, bind.isDisableInstallation() de platform_model.dart
      if (!bind.mainIsInstalled()) {
        // bind.mainIsInstalled() de common.dart
        return _buildInstallCard(
          "deBruin SISTEMAS",
          bind.isOutgoingOnly()
              ? ""
              : "Para melhor experiência, instale o serviço deBruin Remote Access.",
          "Instalar Serviço",
          () async {
            // rustDeskWinManager.closeAllSubWindows(); // Específico de desktop
            bind.mainGotoInstall(); // bind.mainGotoInstall de common.dart
          },
        );
      } else if (bind.mainIsInstalledLowerVersion()) {
        // bind.mainIsInstalledLowerVersion() de common.dart
        return _buildInstallCard(
          "deBruin SISTEMAS",
          "Uma versão mais recente do deBruin SISTEMAS está disponível.",
          "Entre em contato com o Suporte",
          () async {
            // rustDeskWinManager.closeAllSubWindows(); // Específico de desktop
            bind.mainUpdateMe(); // bind.mainUpdateMe de common.dart
          },
        );
      }
    }
    // Lógica para macOS (se aplicável ao mobile/web)
    else if (isMacOS) {
      // isMacOS de platform_model.dart
      final isOutgoingOnly = bind.isOutgoingOnly();
      if (!(isOutgoingOnly || bind.mainIsCanScreenRecording(prompt: false))) {
        // bind.mainIsCanScreenRecording() de common.dart
        return _buildInstallCard(
          "Permissões",
          "Para funcionar corretamente, configure as permissões de tela.",
          "Configurar",
          () async {
            bind.mainIsCanScreenRecording(prompt: true);
            // watchIsCanScreenRecording = true; // Isso seria um campo do State, não acessível aqui em StatelessWidget
          },
          help: 'Ajuda',
          link: translate(
            "doc_mac_permission",
          ), // translate, doc_mac_permission
        );
      } else if (!isOutgoingOnly && !bind.mainIsProcessTrusted(prompt: false)) {
        // bind.mainIsProcessTrusted()
        return _buildInstallCard(
          "Permissões",
          "Configure as permissões de acessibilidade.",
          "Configurar",
          () async {
            bind.mainIsProcessTrusted(prompt: true);
            // watchIsProcessTrust = true;
          },
          help: 'Ajuda',
          link: translate("doc_mac_permission"),
        );
      } else if (!bind.mainIsCanInputMonitoring(prompt: false)) {
        // bind.mainIsCanInputMonitoring()
        return _buildInstallCard(
          "Permissões",
          "Configure as permissões de monitoramento de entrada.",
          "Configurar",
          () async {
            bind.mainIsCanInputMonitoring(prompt: true);
            // watchIsInputMonitoring = true;
          },
          help: 'Ajuda',
          link: translate("doc_mac_permission"),
        );
      } else if (!isOutgoingOnly &&
          !svcStopped.value && // svcStopped é um RxBool de HomePageState
          bind.mainIsInstalled() &&
          !bind.mainIsInstalledDaemon(prompt: false)) {
        // bind.mainIsInstalledDaemon()
        return _buildInstallCard(
          "Serviço",
          "Instale o daemon para melhor funcionamento.",
          "Instalar",
          () async {
            bind.mainIsInstalledDaemon(prompt: true);
          },
        );
      }
    }
    // Lógica para Linux (se aplicável ao mobile/web)
    else if (isLinux) {
      // isLinux de platform_model.dart
      if (bind.isOutgoingOnly()) {
        return Container();
      }
      final LinuxCards = <Widget>[];
      if (bind.isSelinuxEnforcing()) {
        // bind.isSelinuxEnforcing()
        final keyShowSelinuxHelpTip =
            "show-selinux-help-tip"; // Constante de consts.dart
        if (bind.mainGetLocalOption(key: keyShowSelinuxHelpTip) != 'N') {
          // bind.mainGetLocalOption()
          LinuxCards.add(
            _buildInstallCard(
              "Aviso",
              "SELinux pode interferir no funcionamento. Configure as permissões necessárias.",
              "",
              () async {},
              marginTop: LinuxCards.isEmpty ? 20.0 : 5.0,
              help: 'Ajuda',
              link:
                  'https://rustdesk.com/docs/en/client/linux/#permissions-issue',
              closeButton: true,
              closeOption: keyShowSelinuxHelpTip,
            ),
          );
        }
      }
      if (bind.mainCurrentIsWayland()) {
        // bind.mainCurrentIsWayland()
        LinuxCards.add(
          _buildInstallCard(
            "Aviso",
            "Wayland pode ter limitações. Recomendamos X11 para melhor compatibilidade.",
            "",
            () async {},
            marginTop: LinuxCards.isEmpty ? 20.0 : 5.0,
            help: 'Ajuda',
            link: 'https://rustdesk.com/docs/en/client/linux/#x11-required',
          ),
        );
      } else if (bind.mainIsLoginWayland()) {
        // bind.mainIsLoginWayland()
        LinuxCards.add(
          _buildInstallCard(
            "Aviso",
            "Tela de login Wayland não é suportada.",
            "",
            () async {},
            marginTop: LinuxCards.isEmpty ? 20.0 : 5.0,
            help: 'Ajuda',
            link: 'https://rustdesk.com/docs/en/client/linux/#login-screen',
          ),
        );
      }
      if (LinuxCards.isNotEmpty) {
        return Column(children: LinuxCards);
      }
    }
    // Botão de "Sair" (adaptado para o contexto mobile/web)
    // Se a aplicação é incoming-only, oferece a opção de sair
    if (bind.isIncomingOnly()) {
      return Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          // Usado ElevatedButton
          onPressed: () {
            SystemNavigator.pop(); // Fecha a aplicação
            if (isWindows) {
              // isWindows de platform_model.dart
              exit(0); // Força saída em Windows
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: kDeBruinAccentRed, // Cor personalizada
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text(
            'Sair', // Texto adaptado
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ).marginAll(14); // .marginAll() é do GetX
    }
    return Container();
  }

  // _buildInstallCard adaptado para cores e layout
  Widget _buildInstallCard(
    String title,
    String content,
    String btnText,
    GestureTapCallback onPressed, {
    double marginTop = 20.0,
    String? help,
    String? link,
    bool? closeButton,
    String? closeOption,
    Color? cardColor,
    Color? borderColor,
    Color? textColor,
    bool isSystemError =
        false, // Novo parâmetro para diferenciar erros de sistema
  }) {
    if (bind.mainGetBuildinOption(key: kOptionHideHelpCards) ==
            'Y' && // kOptionHideHelpCards
        content != 'install_daemon_tip') {
      // install_daemon_tip
      return const SizedBox();
    }
    void closeCard() async {
      if (closeOption != null) {
        await bind.mainSetLocalOption(
          key: closeOption,
          value: 'N',
        ); // bind.mainSetLocalOption
        // isCardClosed é uma variável do _DesktopHomePageState, não acessível diretamente aqui.
        // Se precisar esconder o card, pode-se usar um Provider ou GetX Controller.
        // Para simplicidade, apenas a opção será definida.
      }
    }

    final defaultCardColor =
        isSystemError
            ? kDeBruinAccentRed.withOpacity(0.1)
            : kDeBruinPrimaryBlue;
    final defaultBorderColor =
        isSystemError
            ? kDeBruinAccentRed.withOpacity(0.3)
            : kDeBruinPrimaryBlue.withOpacity(0.3);
    final defaultTextColor = isSystemError ? kDeBruinAccentRed : Colors.white;

    return Stack(
      children: [
        Container(
          margin: EdgeInsets.fromLTRB(
            20, // Margem lateral
            marginTop,
            20, // Margem lateral
            bind.isIncomingOnly()
                ? marginTop
                : 0, // Margem inferior se incoming-only
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: cardColor ?? defaultCardColor,
              border: Border.all(
                color: borderColor ?? defaultBorderColor,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        translate(title),
                        style: TextStyle(
                          color: textColor ?? defaultTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                if (content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      translate(content),
                      style: TextStyle(
                        height: 1.5,
                        color: textColor ?? defaultTextColor,
                        fontWeight: FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                if (btnText.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: onPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: kDeBruinPrimaryBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
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
                    ],
                  ),
                if (help != null)
                  Center(
                    child: InkWell(
                      onTap: () async => await launchUrl(Uri.parse(link!)),
                      child: Text(
                        translate(help),
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: textColor ?? defaultTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ).marginOnly(top: 10),
                  ),
              ],
            ),
          ),
        ),
        if (closeButton != null && closeButton == true)
          Positioned(
            top: 18,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              onPressed: closeCard,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: gFFI.serverModel,
      child: Consumer<ServerModel>(
        builder: (context, model, child) {
          // Lógica para exibir mensagens de erro do sistema
          Widget systemErrorWidget = Container();
          if (systemError.isNotEmpty) {
            systemErrorWidget = _buildInstallCard(
              "",
              systemError,
              "",
              () {},
              cardColor: Colors.red.withOpacity(0.1),
              borderColor: Colors.red.withOpacity(0.5),
              textColor: Colors.red[800],
              isSystemError: true,
              // Não há closeButton para erros de sistema persistentes geralmente
            );
          }

          Widget svcStoppedWidget = Container();
          // Obx é necessário se svcStopped for um RxBool que muda fora do setState desta classe
          // Como svcStopped é passado do HomePageState (que é StatefulWidget),
          // o rebuild de ServerPageContent já reage à mudança de svcStopped.value.
          // Mas se svcStopped fosse observado diretamente no _DesktopHomePageState,
          // o Obx seria necessário aqui.
          if (svcStopped.value) {
            svcStoppedWidget = _buildInstallCard(
              "Serviço Parado",
              "Por favor, inicie o serviço para permitir conexões.",
              "",
              () {},
              cardColor: Colors.orange.withOpacity(0.1),
              borderColor: Colors.orange.withOpacity(0.5),
              textColor: Colors.orange[800],
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Logo da empresa (Personalizado)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: kDeBruinPrimaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: kDeBruinPrimaryBlue.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.business,
                    size: 60,
                    color: kDeBruinPrimaryBlue,
                  ),
                ),

                const SizedBox(height: 20),

                // Título e subtítulo da empresa (Personalizado)
                Text(
                  'deBruin SISTEMAS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kDeBruinPrimaryBlue,
                  ),
                ),
                Text(
                  'Acesso Remoto Profissional',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),

                const SizedBox(height: 30),

                // Status do Servidor
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kDeBruinAccentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: kDeBruinAccentGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.security,
                        color: kDeBruinAccentGreen,
                        size: 24,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Servidor Ativo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kDeBruinAccentGreen,
                              ),
                            ),
                            Text(
                              'Aguardando conexões...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Indicador de status online/offline
                      Obx(
                        () => Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                svcStopped.value
                                    ? Colors.red
                                    : Colors.green, // Cor dinâmica
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                systemErrorWidget, // Exibe o erro do sistema
                svcStoppedWidget, // Exibe o aviso de serviço parado

                _buildIDBoard(context, model), // O ID Card
                // _buildPasswordBoard(context, model), // Card de senha removido

                // Outros help cards (adaptados do original.dart)
                // A lógica de buildHelpCards é complexa, vou replicar a chamada aqui.
                // Note que _buildHelpCards é um método do ServerPageContent, não de _HomePageState.
                _buildHelpCards(stateGlobal.updateUrl.value, context),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ChatPageContent (Mantido como estava, mas com construtor para ser const)
class ChatPageContent extends PageShape {
  const ChatPageContent({Key? key})
    : super(key: key, title: 'Chat', icon: const Icon(Icons.chat));

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat,
            size: 64,
            color: kDeBruinPrimaryBlue,
          ), // Cor personalizada
          SizedBox(height: 20),
          Text(
            'Chat deBruin',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kDeBruinPrimaryBlue, // Cor personalizada
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Em desenvolvimento',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// SettingsPageContent (Mantido como estava, mas com construtor para ser const)
class SettingsPageContent extends PageShape {
  const SettingsPageContent({Key? key})
    : super(key: key, title: 'Configurações', icon: const Icon(Icons.settings));

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings,
            size: 64,
            color: kDeBruinPrimaryBlue,
          ), // Cor personalizada
          SizedBox(height: 20),
          Text(
            'Configurações deBruin',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kDeBruinPrimaryBlue, // Cor personalizada
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Em desenvolvimento',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// ====================================================================================================
// WebHomePage (Mantido do original.dart)
// ====================================================================================================

class WebHomePage extends StatelessWidget {
  // connectionPage foi mantida, mas seus appBarActions podem ser ajustados.
  // Se a ConnectionPage for removida da lista de _pages no mobile,
  // sua AppBarActions também pode ser vazia aqui, ou ter apenas as configurações.
  final connectionPage = ConnectionPage(
    // ConnectionPage precisa ser definida/importada
    appBarActions: <Widget>[
      const WebSettingsPage(),
    ], // WebSettingsPage precisa ser definida/importada
  );

  @override
  Widget build(BuildContext context) {
    stateGlobal.isInMainPage =
        true; // stateGlobal precisa ser definido/importado
    handleUnilink(context); // handleUnilink precisa ser definido/importado
    return Scaffold(
      // backgroundColor: MyTheme.grayBg, // MyTheme.grayBg não está definido. Pode usar Colors.grey[50]
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "${bind.mainGetAppNameSync()} (Preview)",
        ), // bind.mainGetAppNameSync() precisa ser definido/importado
        actions: connectionPage.appBarActions,
      ),
      body: connectionPage,
    );
  }

  // handleUnilink e connect (funções auxiliares para WebHomePage)
  handleUnilink(BuildContext context) {
    // webInitialLink precisa ser definido/importado
    if (webInitialLink.isEmpty) {
      // webInitialLink precisa ser definido/importado
      return;
    }
    final link = webInitialLink;
    webInitialLink = '';
    final splitter = ["/#/", "/#", "#/", "#"];
    var fakelink = '';
    for (var s in splitter) {
      if (link.contains(s)) {
        var list = link.split(s);
        if (list.length < 2 || list[1].isEmpty) {
          return;
        }
        list.removeAt(0);
        fakelink = "rustdesk://${list.join(s)}";
        break;
      }
    }
    if (fakelink.isEmpty) {
      return;
    }
    final uri = Uri.tryParse(fakelink);
    if (uri == null) {
      return;
    }
    final args = urlLinkToCmdArgs(
      uri,
    ); // urlLinkToCmdArgs precisa ser definido/importado
    if (args == null || args.isEmpty) {
      return;
    }
    bool isFileTransfer = false;
    bool isViewCamera = false;
    bool isTerminal = false;
    String? id;
    String? password;
    for (int i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--connect':
        case '--play':
          id = args[i + 1];
          i++;
          break;
        case '--file-transfer':
          isFileTransfer = true;
          id = args[i + 1];
          i++;
          break;
        case '--view-camera':
          isViewCamera = true;
          id = args[i + 1];
          i++;
          break;
        case '--terminal':
          isTerminal = true;
          id = args[i + 1];
          i++;
          break;
        case '--terminal-admin':
          setEnvTerminalAdmin(); // setEnvTerminalAdmin precisa ser definido/importado
          isTerminal = true;
          id = args[i + 1];
          i++;
          break;
        case '--password':
          password = args[i + 1];
          i++;
          break;
        default:
          break;
      }
    }
    if (id != null) {
      connect(
        // connect precisa ser definido/importado
        context,
        id,
        isFileTransfer: isFileTransfer,
        isViewCamera: isViewCamera,
        isTerminal: isTerminal,
        password: password,
      );
    }
  }
}

// =======================================================================
// Funções e classes globais que estavam no arquivo original
// e que são usadas em múltiplos lugares.
// Recomenda-se que estas sejam movidas para `common.dart` ou `utils/` files.
// =======================================================================

// setPasswordDialog (Definição da função global)
void setPasswordDialog({VoidCallback? notEmptyCallback}) async {
  final pw = await bind.mainGetPermanentPassword();
  final p0 = TextEditingController(text: pw);
  final p1 = TextEditingController(text: pw);
  var errMsg0 = "";
  var errMsg1 = "";
  final RxString rxPass = pw.trim().obs; // RxString e .obs do GetX
  final rules = [
    DigitValidationRule(), // De common/widgets/custom_password.dart
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
      // De common/widgets/custom_password.dart
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
                  child:
                      TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: translate('Password'),
                          errorText: errMsg0.isNotEmpty ? errMsg0 : null,
                        ),
                        controller: p0,
                        autofocus: true,
                        onChanged: (value) {
                          rxPass.value = value.trim();
                          setState(() {
                            errMsg0 = '';
                          });
                        },
                        maxLength: maxLength,
                      ).workaroundFreezeLinuxMint(), // Extensão de TextField para workaround
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: PasswordStrengthIndicator(password: rxPass),
                ), // De common/widgets/custom_password.dart
              ],
            ).marginSymmetric(vertical: 8), // Extensão do GetX
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child:
                      TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: translate('Confirmation'),
                          errorText: errMsg1.isNotEmpty ? errMsg1 : null,
                        ),
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
            Obx(
              () => Wrap(
                runSpacing: 8,
                spacing: 4,
                children:
                    rules.map((e) {
                      var checked = e.validate(rxPass.value.trim());
                      return Chip(
                        label: Text(
                          e.name,
                          style: TextStyle(
                            color:
                                checked
                                    ? const Color(0xFF0A9471)
                                    : const Color.fromARGB(255, 198, 86, 157),
                          ),
                        ),
                        backgroundColor:
                            checked
                                ? const Color(0xFFD0F7ED)
                                : const Color.fromARGB(255, 247, 205, 232),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        dialogButton(
          "Cancel",
          onPressed: close,
          isOutline: true,
        ), // De widgets/button.dart
        dialogButton("OK", onPressed: submit),
      ],
      onSubmit: submit,
      onCancel: close,
    );
  });
}

// handleUpdate (Esta função estava no seu `original.dart` e é usada em _buildHelpCards)
void handleUpdate(String updateUrl) {
  // Exemplo de como usar UpdateProgress. Você pode precisar importar de desktop/widgets/update_progress.dart
  // gFFI.dialogManager.show(UpdateProgress(updateUrl: updateUrl));
  // Ou você pode simplesmente launchUrl para o updateUrl se não quiser um widget de progresso customizado.
  launchUrl(Uri.parse(updateUrl));
}

// Outras funções e classes que podem ser globais ou em `common.dart`
// Por exemplo:
// - `buildRemoteBlock`
// - `canBeBlocked`
// - `isInHomePage`
// - `mainGetBoolOption`
// - `mainGetAppNameSync`
// - `mainGetNewVersion`
// - `mainIsInstalled`, `mainIsInstalledLowerVersion`, `mainGotoInstall`, `mainUpdateMe`
// - `mainIsCanScreenRecording`, `mainIsProcessTrusted`, `mainIsCanInputMonitoring`, `osxCanRecordAudio`, `PermissionAuthorizeType`
// - `mainIsInstalledDaemon`, `mainIsSelinuxEnforcing`, `mainGetLocalOption`, `mainCurrentIsWayland`, `mainIsLoginWayland`
// - `rustDeskWinManager`, `onActiveWindowChanged`, `WindowType`, `kWindow*` constants
// - `parseParamScreenRect`, `connectMainDesktop`, `listenUniLinks`
// - `imcomingOnlyHomeSize`, `getIncomingOnlyHomeSize`, `shouldBeBlocked`
// - `translate`, `showToast`
// - `workaroundFreezeLinuxMint` (extensão)
// - `DigitValidationRule`, `UppercaseValidationRule`, `LowercaseValidationRule`, `MinCharactersValidationRule` (regras de validação de senha)
// - `PasswordStrengthIndicator`, `CustomAlertDialog`
// - `dialogButton` (widget de botão customizado)
// - `MyTheme` (se você tem um tema customizado)
// - `kOptionStopService`, `kUsePermanentPassword`, `kOptionHideHelpCards`, `kWindow*` (constantes)
