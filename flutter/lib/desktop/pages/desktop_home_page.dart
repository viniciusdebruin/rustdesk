import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart'; // Mantido do original
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/animated_rotation_widget.dart';
import 'package:flutter_hbb/common/widgets/custom_password.dart';
import 'package:flutter_hbb/consts.dart'; // Para kOptionHideHelpCards, kOptionStopService, kUsePermanentPassword
import 'package:flutter_hbb/desktop/pages/connection_page.dart'; // Mantido do original, mas ConnectionPage será removida da UI
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart';
import 'package:flutter_hbb/desktop/widgets/update_progress.dart'; // Mantido do original
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
import '../widgets/button.dart'; // Para FixedWidthButton, dialogButton, se usados

// Cor primária azul deBruin
const Color kDeBruinPrimaryBlue = Color(0xFF2F65BA);
// Cor de destaque verde deBruin
const Color kDeBruinAccentGreen = Color(0xFF4CAF50);
// Cor de destaque rosa/vermelho
const Color kDeBruinAccentRed = Color(0xFFf5576c);

class DesktopHomePage extends StatefulWidget {
  const DesktopHomePage({Key? key}) : super(key: key);

  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends State<DesktopHomePage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final _leftPaneScrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;
  var systemError = '';
  StreamSubscription?
  _uniLinksSubscription; // Timer foi renomeado para StreamSubscription em alguns contextos
  var svcStopped = false.obs;
  var watchIsCanScreenRecording = false;
  var watchIsProcessTrust = false;
  var watchIsInputMonitoring = false;
  var watchIsCanRecordAudio = false;
  Timer? _updateTimer; // Declarado como Timer?
  bool isCardClosed = false;

  final RxBool _editHover = false.obs;
  final RxBool _block = false.obs;

  final GlobalKey _childKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Remover a Row que dividia o LeftPane do RightPane
    // O buildLeftPane agora ocupará toda a largura.
    return _buildBlock(child: buildLeftPane(context));
  }

  Widget _buildBlock({required Widget child}) {
    return buildRemoteBlock(
      block: _block,
      mask: true,
      use: canBeBlocked,
      child: child,
    );
  }

  Widget buildLeftPane(BuildContext context) {
    // A lógica isIncomingOnly e isOutgoingOnly é relevante para o RustDesk
    // mas vamos simplificar a UI para focar no "apenas exibir ID".
    // Isso significa que a interface será mais próxima de um incoming-only client.
    final isIncomingOnly =
        bind.isIncomingOnly(); // Se for true, não mostra tela de conexão
    // final isOutgoingOnly = bind.isOutgoingOnly(); // Menos relevante para esta UI

    final children = <Widget>[
      const SizedBox(height: 20),

      // Título da empresa (Personalizado)
      Align(
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(
              'deBruin SISTEMAS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kDeBruinPrimaryBlue, // Cor personalizada
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Acesso Remoto Profissional', // Personalizado
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF667eea), // Cor baseada no seu input anterior
                fontWeight: FontWeight.w500,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 20),

      // Logo/Ícone da empresa (Personalizado)
      Align(
        alignment: Alignment.center,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: kDeBruinPrimaryBlue.withOpacity(0.1), // Cor personalizada
            border: Border.all(
              color: kDeBruinPrimaryBlue.withOpacity(0.3), // Cor personalizada
              width: 2,
            ),
          ),
          child: Icon(
            Icons.business,
            size: 80,
            color: kDeBruinPrimaryBlue,
          ), // Ícone personalizado
        ),
      ),

      const SizedBox(height: 20),

      // Card de status do servidor (Adaptado)
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: kDeBruinAccentGreen.withOpacity(0.1), // Cor personalizada
          border: Border.all(
            color: kDeBruinAccentGreen.withOpacity(0.3), // Cor personalizada
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kDeBruinAccentGreen, // Cor personalizada
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.security,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Servidor Ativo', // Texto personalizado
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kDeBruinAccentGreen, // Cor personalizada
                      ),
                    ),
                    Text(
                      'Aguardando conexões remotas...', // Texto personalizado
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Ícone de status online
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green, // Indicador verde de online
                ),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(height: 20),

      // Apenas o ID (Removendo o buildPasswordBoard)
      buildIDBoard(context),
      // buildPasswordBoard(context), // Removido para exibir apenas o ID

      // buildHelpCards e buildPluginEntry mantidos, se forem úteis
      FutureBuilder<Widget>(
        future: Future.value(
          // Obx é do GetX, necessário importar 'package:get/get.dart';
          Obx(() => buildHelpCards(stateGlobal.updateUrl.value)),
        ),
        builder: (_, data) {
          if (data.hasData) {
            if (isIncomingOnly) {
              if (isInHomePage()) {
                // isInHomePage() precisa ser definido ou importado
                Future.delayed(const Duration(milliseconds: 300), () {
                  _updateWindowSize();
                });
              }
            }
            return data.data!;
          } else {
            return const Offstage();
          }
        },
      ),
      buildPluginEntry(),
    ];

    // Se é incomingOnly, adiciona o status do serviço
    if (isIncomingOnly) {
      children.addAll([
        const Divider(
          color: kDeBruinPrimaryBlue,
          thickness: 2,
        ), // Cor personalizada
        // OnlineStatusWidget deve estar definido ou importado
        Padding(
          padding: const EdgeInsets.only(bottom: 6, right: 6),
          child: OnlineStatusWidget(
            onSvcStatusChanged: () {
              if (isInHomePage()) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  _updateWindowSize();
                });
              }
            },
          ),
        ),
      ]);
    }

    final textColor = Theme.of(context).textTheme.titleLarge?.color;
    return ChangeNotifierProvider.value(
      value: gFFI.serverModel,
      child: Container(
        // Removido a largura fixa, para se ajustar ao conteúdo ou ao Expanded se houver Row principal
        // width: isIncomingOnly ? 280.0 : 200.0,
        color: Theme.of(context).colorScheme.background,
        child: Stack(
          children: [
            Column(
              children: [
                SingleChildScrollView(
                  controller: _leftPaneScrollController,
                  child: Column(key: _childKey, children: children),
                ),
                Expanded(
                  child: Container(),
                ), // Para empurrar os elementos para cima
              ],
            ),
            // O botão de configurações na parte inferior esquerda (isOutgoingOnly)
            // Se o objetivo é incoming-only, isso pode ser ajustado ou removido.
            // Mantido com a condição original, mas estilizado com as novas cores.
            if (bind.isOutgoingOnly())
              Positioned(
                bottom: 6,
                left: 12,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: kDeBruinPrimaryBlue.withOpacity(
                          0.1,
                        ), // Cor personalizada
                      ),
                      child: Obx(
                        () => Icon(
                          Icons.settings,
                          color:
                              _editHover.value
                                  ? textColor
                                  : Colors.grey.withOpacity(0.5),
                          size: 22,
                        ),
                      ),
                    ),
                    onTap: () {
                      if (DesktopSettingPage.tabKeys.isNotEmpty) {
                        DesktopSettingPage.switch2page(
                          DesktopSettingPage.tabKeys[0],
                        );
                      }
                    },
                    onHover: (value) => _editHover.value = value,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Removendo buildRightPane completamente, pois a conexão não será iniciada a partir daqui.
  // buildRightPane(BuildContext context) {
  //   return Container(
  //     color: Theme.of(context).scaffoldBackgroundColor,
  //     child: ConnectionPage(),
  //   );
  // }

  // Ajustado o buildIDBoard para usar as novas cores e ser mais proeminente
  buildIDBoard(BuildContext context) {
    final model = gFFI.serverModel;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        border: Border.all(
          color: kDeBruinPrimaryBlue.withOpacity(0.3), // Cor personalizada
          width: 2,
        ),
        boxShadow: [
          // Adicionado sombra para destaque
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
                        color: kDeBruinPrimaryBlue, // Cor personalizada
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
                        color: kDeBruinPrimaryBlue, // Cor personalizada
                      ),
                    ),
                  ],
                ),
                buildPopupMenu(context), // Menu de configurações
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
                  vertical: 18, // Aumentado padding vertical
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
                      : 'Carregando ID...', // Texto mais claro
                  style: TextStyle(
                    fontSize: 24, // Aumentado tamanho da fonte
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

  // buildPopupMenu é mantido, ajustado para novas cores se for o caso
  Widget buildPopupMenu(BuildContext context) {
    final textColor = Theme.of(context).textTheme.titleLarge?.color;
    RxBool hover = false.obs;
    return InkWell(
      onTap: DesktopTabPage.onAddSetting,
      child: Tooltip(
        message: translate('Settings'),
        child: Obx(
          () => CircleAvatar(
            radius: 15,
            backgroundColor:
                hover.value
                    ? Theme.of(context).scaffoldBackgroundColor
                    : Theme.of(context).colorScheme.background,
            child: Icon(
              Icons.more_vert_outlined,
              size: 20,
              color:
                  hover.value
                      ? kDeBruinPrimaryBlue
                      : textColor?.withOpacity(0.5), // Cor personalizada
            ),
          ),
        ),
      ),
      onHover: (value) => hover.value = value,
    );
  }

  // buildPasswordBoard e buildPasswordBoard2 foram removidos completamente da UI
  // para focar apenas na exibição do ID e remover a opção de conexão.
  // Se precisar de alguma funcionalidade de senha oculta, ela precisaria ser reimplementada.

  // buildPresetPasswordWarning, buildTip, e outras funções que não se encaixam mais na nova UI
  // foram implicitamente removidas por não serem chamadas em buildLeftPane.

  Widget buildHelpCards(String updateUrl) {
    // Mantém a lógica de help cards original do RustDesk
    // Adaptação de cores e textos para "deBruin SISTEMAS" onde relevante.
    // kDeBruinAccentRed para botões de ação/alerta
    if (!bind.isCustomClient() &&
        updateUrl.isNotEmpty &&
        !isCardClosed &&
        bind.mainUriPrefixSync().contains('rustdesk')) {
      final isToUpdate = (isWindows || isMacOS) && bind.mainIsInstalled();
      String btnText = isToUpdate ? 'Update' : 'Download';
      GestureTapCallback onPressed = () async {
        final Uri url = Uri.parse('https://rustdesk.com/download');
        await launchUrl(url);
      };
      if (isToUpdate) {
        onPressed = () {
          handleUpdate(
            updateUrl,
          ); // handleUpdate precisa estar definido ou importado
        };
      }
      return buildInstallCard(
        "Status", // Pode ser "Atualização Disponível"
        "${translate("new-version-of-{${bind.mainGetAppNameSync()}}-tip")} (${bind.mainGetNewVersion()}).",
        btnText,
        onPressed,
        closeButton: true,
      );
    }
    if (systemError.isNotEmpty) {
      return buildInstallCard(
        "",
        systemError,
        "",
        () {},
        // Cor para SystemError pode ser vermelha
        cardColor: kDeBruinAccentRed.withOpacity(0.1),
        borderColor: kDeBruinAccentRed.withOpacity(0.3),
        textColor: kDeBruinAccentRed,
      );
    }

    if (isWindows && !bind.isDisableInstallation()) {
      if (!bind.mainIsInstalled()) {
        return buildInstallCard(
          "deBruin SISTEMAS", // Título adaptado
          bind.isOutgoingOnly()
              ? ""
              : "Para melhor experiência, instale o serviço deBruin Remote Access.", // Texto adaptado
          "Instalar Serviço", // Texto adaptado
          () async {
            await rustDeskWinManager.closeAllSubWindows();
            bind.mainGotoInstall();
          },
        );
      } else if (bind.mainIsInstalledLowerVersion()) {
        return buildInstallCard(
          "deBruin SISTEMAS", // Título adaptado
          "Uma versão mais recente do deBruin Remote Access está disponível.", // Texto adaptado
          "Entre em contato com o Suporte", // Texto adaptado
          () async {
            await rustDeskWinManager.closeAllSubWindows();
            bind.mainUpdateMe();
          },
        );
      }
    } else if (isMacOS) {
      final isOutgoingOnly = bind.isOutgoingOnly();
      if (!(isOutgoingOnly || bind.mainIsCanScreenRecording(prompt: false))) {
        return buildInstallCard(
          "Permissões", // Título adaptado
          "Para funcionar corretamente, configure as permissões de tela.", // Texto adaptado
          "Configurar", // Texto adaptado
          () async {
            bind.mainIsCanScreenRecording(prompt: true);
            watchIsCanScreenRecording = true;
          },
          help: 'Ajuda',
          link: translate("doc_mac_permission"),
        );
      } else if (!isOutgoingOnly && !bind.mainIsProcessTrusted(prompt: false)) {
        return buildInstallCard(
          "Permissões", // Título adaptado
          "Configure as permissões de acessibilidade.", // Texto adaptado
          "Configurar", // Texto adaptado
          () async {
            bind.mainIsProcessTrusted(prompt: true);
            watchIsProcessTrust = true;
          },
          help: 'Ajuda',
          link: translate("doc_mac_permission"),
        );
      } else if (!bind.mainIsCanInputMonitoring(prompt: false)) {
        return buildInstallCard(
          "Permissões", // Título adaptado
          "Configure as permissões de monitoramento de entrada.", // Texto adaptado
          "Configurar", // Texto adaptado
          () async {
            bind.mainIsCanInputMonitoring(prompt: true);
            watchIsInputMonitoring = true;
          },
          help: 'Ajuda',
          link: translate("doc_mac_permission"),
        );
      } else if (!isOutgoingOnly &&
          !svcStopped.value &&
          bind.mainIsInstalled() &&
          !bind.mainIsInstalledDaemon(prompt: false)) {
        return buildInstallCard(
          "Serviço", // Título adaptado
          "Instale o daemon para melhor funcionamento.", // Texto adaptado
          "Instalar", // Texto adaptado
          () async {
            bind.mainIsInstalledDaemon(prompt: true);
          },
        );
      }
    } else if (isLinux) {
      if (bind.isOutgoingOnly()) {
        return Container();
      }
      final LinuxCards = <Widget>[];
      if (bind.isSelinuxEnforcing()) {
        final keyShowSelinuxHelpTip = "show-selinux-help-tip";
        if (bind.mainGetLocalOption(key: keyShowSelinuxHelpTip) != 'N') {
          LinuxCards.add(
            buildInstallCard(
              "Aviso", // Título adaptado
              "SELinux pode interferir no funcionamento. Configure as permissões necessárias.", // Texto adaptado
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
        LinuxCards.add(
          buildInstallCard(
            "Aviso", // Título adaptado
            "Wayland pode ter limitações. Recomendamos X11 para melhor compatibilidade.", // Texto adaptado
            "",
            () async {},
            marginTop: LinuxCards.isEmpty ? 20.0 : 5.0,
            help: 'Ajuda',
            link: 'https://rustdesk.com/docs/en/client/linux/#x11-required',
          ),
        );
      } else if (bind.mainIsLoginWayland()) {
        LinuxCards.add(
          buildInstallCard(
            "Aviso", // Título adaptado
            "Tela de login Wayland não é suportada.", // Texto adaptado
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
    // Botão "Sair" para modo incoming-only
    if (bind.isIncomingOnly()) {
      return Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          // Usei ElevatedButton para corresponder ao estilo do seu outro código
          onPressed: () {
            SystemNavigator.pop();
            if (isWindows) {
              exit(0);
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
      ).marginAll(
        14,
      ); // O .marginAll() é um extensor do GetX, comum no RustDesk
    }
    return Container();
  }

  // buildInstallCard com parâmetros de cor adicionais para flexibilidade
  Widget buildInstallCard(
    String title,
    String content,
    String btnText,
    GestureTapCallback onPressed, {
    double marginTop = 20.0,
    String? help,
    String? link,
    bool? closeButton,
    String? closeOption,
    Color? cardColor, // Novo parâmetro
    Color? borderColor, // Novo parâmetro
    Color? textColor, // Novo parâmetro para o texto interno
  }) {
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

    // Cores padrão para o card, se não forem fornecidas
    final defaultCardColor = kDeBruinPrimaryBlue; // Seu azul padrão
    final defaultBorderColor = kDeBruinPrimaryBlue.withOpacity(
      0.3,
    ); // Borda padrão

    return Stack(
      children: [
        Container(
          margin: EdgeInsets.fromLTRB(
            20, // Ajustado para corresponder ao novo layout
            marginTop,
            20, // Ajustado para corresponder ao novo layout
            bind.isIncomingOnly() ? marginTop : 0,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                15,
              ), // Arredondamento padrão de 15
              color: cardColor ?? defaultCardColor, // Usa cor passada ou padrão
              border: Border.all(
                color:
                    borderColor ??
                    defaultBorderColor, // Usa cor passada ou padrão
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
                          color:
                              textColor ??
                              Colors.white, // Usa cor passada ou branco
                          fontWeight: FontWeight.bold,
                          fontSize: 18, // Tamanho adaptado
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
                        color:
                            textColor ??
                            Colors.white, // Usa cor passada ou branco
                        fontWeight: FontWeight.normal,
                        fontSize: 14, // Tamanho adaptado
                      ),
                    ),
                  ),
                if (btnText.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        // Substituído FixedWidthButton por ElevatedButton para consistência
                        onPressed: onPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor:
                              kDeBruinPrimaryBlue, // Cor do texto do botão (adaptado)
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
                          color:
                              textColor ??
                              Colors.white, // Usa cor passada ou branco
                          fontSize: 13, // Tamanho adaptado
                          fontWeight: FontWeight.w500, // Peso adaptado
                        ),
                      ),
                    ).marginOnly(top: 10), // Usando .marginOnly do GetX
                  ),
              ],
            ),
          ),
        ),
        if (closeButton != null && closeButton == true)
          Positioned(
            top: 18,
            right: 20, // Ajustado para 20 para ser consistente com o padding
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              onPressed: closeCard,
            ),
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    // Use Timer.periodic e não StreamSubscription diretamente para esta atribuição
    _updateTimer = Timer.periodic(const Duration(seconds: 1), () async {
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
          setState(() {}); // Notifique a UI sobre a mudança
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
    // Necessário importar 'package:get/get.dart'
    Get.put<RxBool>(svcStopped, tag: 'stop-service');
    rustDeskWinManager.registerActiveWindowListener(onActiveWindowChanged);

    // Mapeamento de Screen para Map
    // Esta função foi colocada aqui para o contexto correto do setMethodHandler
    Map<String, dynamic> screenToMap(window_size.Screen screen) => {
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
        "[Main] call ${call.method} with args ${call.arguments} from window $fromWindowId",
      );
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
          (await window_size.getScreenList()).map(screenToMap).toList(),
        );
      } else if (call.method == kWindowActionRebuild) {
        reloadCurrentWindow();
      } else if (call.method == kWindowEventShow) {
        await rustDeskWinManager.registerActiveWindow(call.arguments["id"]);
      } else if (call.method == kWindowEventHide) {
        await rustDeskWinManager.unregisterActiveWindow(call.arguments['id']);
      } else if (call.method == kWindowConnect) {
        // Lógica de conexão original, mantida caso seja usada internamente
        // ou para referências, mas a UI de "fazer conexão" foi removida.
        await connectMainDesktop(
          call.arguments['id'],
          isFileTransfer: call.arguments['isFileTransfer'],
          isViewCamera: call.arguments['isViewCamera'],
          isTerminal: call.arguments['isTerminal'],
          isTcpTunneling: call.arguments['isTcpTunneling'],
          isRDP: call.arguments['isRDP'],
          password: call.arguments['password'],
          forceRelay: call.arguments['forceRelay'],
          connToken: call.arguments['connToken'],
        );
      } else if (call.method == kWindowEventMoveTabToNewWindow) {
        final args = call.arguments.split(',');
        int? windowId;
        try {
          windowId = int.parse(args[0]);
        } catch (e) {
          debugPrint("Failed to parse window id '${call.arguments}': $e");
        }
        WindowType? windowType;
        try {
          windowType = WindowType.values.byName(args[3]);
        } catch (e) {
          debugPrint("Failed to parse window type '${call.arguments}': $e");
        }
        if (windowId != null && windowType != null) {
          await rustDeskWinManager.moveTabToNewWindow(
            windowId,
            args[1],
            args[2],
            windowType,
          );
        }
      } else if (call.method == kWindowEventOpenMonitorSession) {
        final args = jsonDecode(call.arguments);
        final windowId = args['window_id'] as int;
        final peerId = args['peer_id'] as String;
        final display = args['display'] as int;
        final displayCount = args['display_count'] as int;
        final windowType = args['window_type'] as int;
        final screenRect = parseParamScreenRect(args);
        await rustDeskWinManager.openMonitorSession(
          windowId,
          peerId,
          display,
          displayCount,
          screenRect,
          windowType,
        );
      } else if (call.method == kWindowEventRemoteWindowCoords) {
        final windowId = int.tryParse(call.arguments);
        if (windowId != null) {
          return jsonEncode(
            await rustDeskWinManager.getOtherRemoteWindowCoords(windowId),
          );
        }
      }
    });
    _uniLinksSubscription =
        listenUniLinks(); // listenUniLinks precisa ser definido ou importado

    if (bind.isIncomingOnly()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateWindowSize();
      });
    }
    WidgetsBinding.instance.addObserver(this);
  }

  _updateWindowSize() {
    RenderObject? renderObject = _childKey.currentContext?.findRenderObject();
    if (renderObject == null) {
      return;
    }
    if (renderObject is RenderBox) {
      final size = renderObject.size;
      if (size != imcomingOnlyHomeSize) {
        // imcomingOnlyHomeSize precisa ser definido ou importado
        imcomingOnlyHomeSize = size;
        windowManager.setSize(
          getIncomingOnlyHomeSize(),
        ); // getIncomingOnlyHomeSize precisa ser definido ou importado
      }
    }
  }

  @override
  void dispose() {
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
      shouldBeBlocked(
        _block,
        canBeBlocked,
      ); // shouldBeBlocked e canBeBlocked precisam ser definidos ou importados
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
          }).toList(), // Adicionado .toList() para compatibilidade
        ],
      ),
    );
  }
}

// Funções globais que estavam no arquivo original e foram movidas para cá para contexto.
// Se elas já estiverem em common.dart ou em outro lugar, remova as duplicatas.

void setPasswordDialog({VoidCallback? notEmptyCallback}) async {
  final pw = await bind.mainGetPermanentPassword();
  final p0 = TextEditingController(text: pw);
  final p1 = TextEditingController(text: pw);
  var errMsg0 = "";
  var errMsg1 = "";
  final RxString rxPass = pw.trim().obs;
  final rules = [
    DigitValidationRule(), // Necessita import de common/widgets/custom_password.dart
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
      // Necessita import de common/widgets/custom_password.dart
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
                      ).workaroundFreezeLinuxMint(), // workaroundFreezeLinuxMint() precisa ser definido ou importado
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: PasswordStrengthIndicator(password: rxPass),
                ), // Necessita import de common/widgets/custom_password.dart
              ],
            ).marginSymmetric(
              vertical: 8,
            ), // .marginSymmetric() é um extensor do GetX, comum no RustDesk
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
        ), // Necessita import de ../widgets/button.dart
        dialogButton("OK", onPressed: submit),
      ],
      onSubmit: submit,
      onCancel: close,
    );
  });
}

// handleUpdate precisa ser definido ou importado se usado no buildHelpCards
void handleUpdate(String updateUrl) {
  // Implementação de handleUpdate, como no RustDesk original
  // ou remova se não for necessário para sua versão
  // Ex: gFFI.dialogManager.show(UpdateProgress(updateUrl: updateUrl));
}
