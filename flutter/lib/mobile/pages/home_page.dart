import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Necessário para Timer e StreamSubscription
import 'dart:io'; // Necessário para exit(0)
import 'dart:convert'; // Necessário para jsonEncode

import 'package:flutter/foundation.dart'; // Para kDebugMode

import '../../common.dart';
import '../../models/platform_model.dart'; // Verifique se contém isWindows, isMacOS, isLinux
import '../../models/state_model.dart';
import '../../models/server_model.dart';
// Adicione imports adicionais que seus widgets e funções customizadas possam precisar
// Exemplo:
// import 'package:flutter_hbb/common/widgets/animated_rotation_widget.dart';
// import 'package:flutter_hbb/common/widgets/custom_password.dart';
// import 'package:flutter_hbb/consts.dart'; // Para kOptionHideHelpCards, kOptionStopService, kUsePermanentPassword
// import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart'; // Para DesktopSettingPage, SettingsTabKey
// import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart'; // Para DesktopTabPage.onAddSetting
// import 'package:flutter_hbb/plugin/ui_manager.dart'; // Para PluginUiManager
// import 'package:flutter_hbb/utils/multi_window_manager.dart'; // Para rustDeskWinManager
// import 'package:get/get.dart'; // Se você usa GetX para Obx, RxBool, etc.
// import 'package:url_launcher/url_launcher.dart'; // Para launchUrl
// import 'package:window_manager/window_manager.dart'; // Para windowManager
// import 'package:window_size/window_size.dart' as window_size; // Para window_size
// import '../widgets/button.dart'; // Para dialogButton

class HomePage extends StatefulWidget {
  // O tipo da GlobalKey deve corresponder ao tipo do State
  static final homeKey = GlobalKey<_HomePageState>();

  HomePage() : super(key: homeKey);

  @override
  // createState deve retornar uma instância de _HomePageState
  _HomePageState createState() => _HomePageState();
}

// Renomeado para _HomePageState por convenção
class _HomePageState extends State<HomePage> {
  var _selectedIndex = 0;
  final List<Widget> _pages = [];

  // Variáveis adicionadas para simular o contexto de DesktopHomePage, se necessário.
  // Ajuste conforme suas necessidades reais e imports.
  var systemError = '';
  StreamSubscription? _updateTimerSubscription;
  var svcStopped =
      false
          .obs; // Se você estiver usando GetX, precisa importar 'package:get/get.dart'
  // final RxBool _editHover = false.obs; // Se usar, importar GetX e definir no State
  // final RxBool _block = false.obs; // Se usar, importar GetX e definir no State

  // Funções de inicialização das páginas
  void refreshPages() {
    setState(() {
      initPages();
    });
  }

  @override
  void initState() {
    super.initState();
    initPages();

    // Exemplo de como você pode integrar a lógica de atualização do servidor
    // do seu DesktopHomePage aqui, se esta HomePage for a principal.
    // Lembre-se de que muitas dessas dependências (bind, gFFI, etc.)
    // precisam ser importadas e configuradas corretamente.
    _updateTimerSubscription = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      // Essas chamadas dependem de 'package:flutter_hbb/models/server_model.dart' e 'package:flutter_hbb/common.dart'
      // e da inicialização correta de `gFFI` e `bind`.
      if (kDebugMode) {
        // Use kDebugMode para logs de depuração
        // print('Fetching ID and checking error...');
      }
      await gFFI.serverModel.fetchID();
      final error = await bind.mainGetError();
      if (systemError != error) {
        setState(() {
          systemError = error;
        });
      }
      final v = await mainGetBoolOption(
        kOptionStopService,
      ); // kOptionStopService precisa ser importado de 'consts.dart'
      if (v != svcStopped.value) {
        setState(() {
          svcStopped.value = v;
        });
      }
    });
  }

  @override
  void dispose() {
    _updateTimerSubscription?.cancel();
    super.dispose();
  }

  void initPages() {
    _pages.clear();
    _pages.add(
      ServerPageContent(systemError: systemError, svcStopped: svcStopped),
    ); // Passa o systemError para o widget filho
    _pages.add(ChatPageContent());
    _pages.add(SettingsPageContent());
  }

  @override
  Widget build(BuildContext context) {
    // Re-chama initPages para atualizar o systemError no ServerPageContent quando houver mudança
    // Isso pode não ser ideal para performance se as páginas forem muito complexas e mudarem constantemente.
    // Uma alternativa seria usar Provider/GetX diretamente dentro de ServerPageContent para reagir a systemError.
    initPages(); // Rebuilds the list of pages whenever HomePageState rebuilds.

    return PopScope(
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
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Color(0xFF2F65BA), // Cor fixa, considerar usar tema
          elevation: 2,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Icon(Icons.business, color: Color(0xFF2F65BA), size: 20),
              ),
              SizedBox(width: 10),
              Text(
                'deBruin SISTEMAS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Color(0xFF2F65BA), // Cor fixa, considerar usar tema
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.6),
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.security),
              label: 'Servidor',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Configurações',
            ),
          ],
        ),
        body: IndexedStack(index: _selectedIndex, children: _pages),
      ),
    );
  }
}

class ServerPageContent extends StatelessWidget {
  final String systemError;
  final RxBool svcStopped; // Se você usa GetX

  const ServerPageContent({
    Key? key,
    required this.systemError,
    required this.svcStopped,
  }) : super(key: key);

  // Exemplo de placeholders para buildIDBoard e buildPasswordBoard
  // Você precisará implementá-los ou importar de outro lugar.
  Widget _buildIDBoard(BuildContext context, ServerModel model) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                      Icon(Icons.computer, color: Color(0xFF2F65BA), size: 20),
                      SizedBox(width: 10),
                      Text(
                        'ID do Dispositivo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2F65BA),
                        ),
                      ),
                    ],
                  ),
                  // Se tiver um menu de contexto como no seu outro código
                  // buildPopupMenu(context),
                ],
              ),
              SizedBox(height: 15),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: model.serverId.text));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('ID copiado!')));
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    model.serverId.text.isNotEmpty
                        ? model.serverId.text
                        : 'Carregando...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordBoard(BuildContext context, ServerModel model) {
    // Implemente a lógica da senha aqui, similar ao seu DesktopHomePage
    // Vai depender de 'get.dart' para Obx, RxBool
    // e de 'flutter_hbb/common/widgets/animated_rotation_widget.dart'
    // e 'flutter_hbb/common/widgets/custom_password.dart'
    // e das funções bind.mainUpdateTemporaryPassword(), DesktopSettingPage.switch2page(), etc.

    // Exemplo simplificado:
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                      Icon(Icons.lock, color: Color(0xFFf5576c), size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Senha de Acesso',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFf5576c),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Color(0xFFf5576c)),
                    onPressed: () {
                      // bind.mainUpdateTemporaryPassword(); // Necessita 'bind'
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Senha atualizada!')),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 15),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: model.serverPasswd.text),
                  );
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Senha copiada!')));
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    model.serverPasswd.text.isNotEmpty
                        ? model.serverPasswd.text
                        : 'Carregando...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // Adicione aqui a lógica de "Change Password" e validação de regras de senha se necessário.
            ],
          ),
        ),
      ),
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
            systemErrorWidget = Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Erro do Sistema: $systemError',
                      style: TextStyle(color: Colors.red[800]),
                    ),
                  ),
                ],
              ),
            );
          }

          Widget svcStoppedWidget = Container();
          if (svcStopped.value) {
            // Se você usa GetX (RxBool), precisa de um Obx aqui
            svcStoppedWidget = Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Serviço parado. Por favor, inicie o serviço.',
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(height: 20),

                // Logo da empresa
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Color(0xFF2F65BA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Color(0xFF2F65BA).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.business,
                    size: 60,
                    color: Color(0xFF2F65BA),
                  ),
                ),

                SizedBox(height: 20),

                Text(
                  'deBruin SISTEMAS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F65BA),
                  ),
                ),

                Text(
                  'Acesso Remoto Profissional',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),

                SizedBox(height: 30),

                // Status do Servidor
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Color(0xFF4CAF50).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Color(0xFF4CAF50), size: 24),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Servidor Ativo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4CAF50),
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
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(
                            0xFF4CAF50,
                          ), // Cor do indicador de status
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                systemErrorWidget, // Exibe o erro do sistema, se houver
                svcStoppedWidget, // Exibe o aviso de serviço parado, se houver
                // ID Card e Password Card usando as funções auxiliares
                _buildIDBoard(context, model),
                _buildPasswordBoard(context, model),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ChatPageContent extends StatelessWidget {
  const ChatPageContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat, size: 64, color: Color(0xFF2F65BA)),
          SizedBox(height: 20),
          Text(
            'Chat deBruin',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F65BA),
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

class SettingsPageContent extends StatelessWidget {
  const SettingsPageContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 64, color: Color(0xFF2F65BA)),
          SizedBox(height: 20),
          Text(
            'Configurações deBruin',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F65BA),
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
