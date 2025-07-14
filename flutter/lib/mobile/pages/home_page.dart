// import 'package:flutter/material.dart';
// import 'package:flutter_hbb/mobile/pages/server_page.dart';
// import 'package:flutter_hbb/mobile/pages/settings_page.dart';
// import 'package:flutter_hbb/web/settings_page.dart';
// import 'package:get/get.dart';
// import '../../common.dart';
// import '../../common/widgets/chat_page.dart';
// import '../../models/platform_model.dart';
// import '../../models/state_model.dart';
// import 'connection_page.dart';

// abstract class PageShape extends Widget {
//   final String title = "";
//   final Widget icon = Icon(null);
//   final List<Widget> appBarActions = [];
// }

// class HomePage extends StatefulWidget {
//   static final homeKey = GlobalKey<HomePageState>();

//   HomePage() : super(key: homeKey);

//   @override
//   HomePageState createState() => HomePageState();
// }

// class HomePageState extends State<HomePage> {
//   var _selectedIndex = 0;
//   int get selectedIndex => _selectedIndex;
//   final List<PageShape> _pages = [];
//   int _chatPageTabIndex = -1;
//   bool get isChatPageCurrentTab => isAndroid
//       ? _selectedIndex == _chatPageTabIndex
//       : false; // change this when ios have chat page

//   void refreshPages() {
//     setState(() {
//       initPages();
//     });
//   }

//   @override
//   void initState() {
//     super.initState();
//     initPages();
//   }

//   void initPages() {
//     _pages.clear();
//     if (!bind.isIncomingOnly()) {
//       _pages.add(ConnectionPage(
//         appBarActions: [],
//       ));
//     }
//     if (isAndroid && !bind.isOutgoingOnly()) {
//       _chatPageTabIndex = _pages.length;
//       _pages
//           .addAll([ChatPage(type: ChatPageType.mobileMain) /*, ServerPage()*/]);
//     }
//     _pages.add(SettingsPage());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//         onWillPop: () async {
//           if (_selectedIndex != 0) {
//             setState(() {
//               _selectedIndex = 0;
//             });
//           } else {
//             return true;
//           }
//           return false;
//         },
//         child: Scaffold(
//           // backgroundColor: MyTheme.grayBg,
//           appBar: AppBar(
//             centerTitle: true,
//             title: appTitle(),
//             actions: _pages.elementAt(_selectedIndex).appBarActions,
//           ),
//           bottomNavigationBar: BottomNavigationBar(
//             key: navigationBarKey,
//             items: _pages
//                 .map((page) =>
//                     BottomNavigationBarItem(icon: page.icon, label: page.title))
//                 .toList(),
//             currentIndex: _selectedIndex,
//             type: BottomNavigationBarType.fixed,
//             selectedItemColor: MyTheme.accent, //
//             unselectedItemColor: MyTheme.darkGray,
//             onTap: (index) => setState(() {
//               // close chat overlay when go chat page
//               if (_selectedIndex != index) {
//                 _selectedIndex = index;
//                 if (isChatPageCurrentTab) {
//                   gFFI.chatModel.hideChatIconOverlay();
//                   gFFI.chatModel.hideChatWindowOverlay();
//                   gFFI.chatModel.mobileClearClientUnread(
//                       gFFI.chatModel.currentKey.connId);
//                 }
//               }
//             }),
//           ),
//           body: _pages.elementAt(_selectedIndex),
//         ));
//   }

//   Widget appTitle() {
//     final currentUser = gFFI.chatModel.currentUser;
//     final currentKey = gFFI.chatModel.currentKey;
//     if (isChatPageCurrentTab &&
//         currentUser != null &&
//         currentKey.peerId.isNotEmpty) {
//       final connected =
//           gFFI.serverModel.clients.any((e) => e.id == currentKey.connId);
//       return Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Tooltip(
//             message: currentKey.isOut
//                 ? translate('Outgoing connection')
//                 : translate('Incoming connection'),
//             child: Icon(
//               currentKey.isOut
//                   ? Icons.call_made_rounded
//                   : Icons.call_received_rounded,
//             ),
//           ),
//           Expanded(
//             child: Center(
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     "${currentUser.firstName}   ${currentUser.id}",
//                   ),
//                   if (connected)
//                     Container(
//                       width: 10,
//                       height: 10,
//                       decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: Color.fromARGB(255, 133, 246, 199)),
//                     ).marginSymmetric(horizontal: 2),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       );
//     }
//     return Text(bind.mainGetAppNameSync());
//   }
// }

// class WebHomePage extends StatelessWidget {
//   final connectionPage =
//       ConnectionPage(appBarActions: <Widget>[const WebSettingsPage()]);

//   @override
//   Widget build(BuildContext context) {
//     stateGlobal.isInMainPage = true;
//     handleUnilink(context);
//     return Scaffold(
//       // backgroundColor: MyTheme.grayBg,
//       appBar: AppBar(
//         centerTitle: true,
//         title: Text("${bind.mainGetAppNameSync()} (Preview)"),
//         actions: connectionPage.appBarActions,
//       ),
//       body: connectionPage,
//     );
//   }

//   handleUnilink(BuildContext context) {
//     if (webInitialLink.isEmpty) {
//       return;
//     }
//     final link = webInitialLink;
//     webInitialLink = '';
//     final splitter = ["/#/", "/#", "#/", "#"];
//     var fakelink = '';
//     for (var s in splitter) {
//       if (link.contains(s)) {
//         var list = link.split(s);
//         if (list.length < 2 || list[1].isEmpty) {
//           return;
//         }
//         list.removeAt(0);
//         fakelink = "rustdesk://${list.join(s)}";
//         break;
//       }
//     }
//     if (fakelink.isEmpty) {
//       return;
//     }
//     final uri = Uri.tryParse(fakelink);
//     if (uri == null) {
//       return;
//     }
//     final args = urlLinkToCmdArgs(uri);
//     if (args == null || args.isEmpty) {
//       return;
//     }
//     bool isFileTransfer = false;
//     bool isViewCamera = false;
//     bool isTerminal = false;
//     String? id;
//     String? password;
//     for (int i = 0; i < args.length; i++) {
//       switch (args[i]) {
//         case '--connect':
//         case '--play':
//           id = args[i + 1];
//           i++;
//           break;
//         case '--file-transfer':
//           isFileTransfer = true;
//           id = args[i + 1];
//           i++;
//           break;
//         case '--view-camera':
//           isViewCamera = true;
//           id = args[i + 1];
//           i++;
//           break;
//         case '--terminal':
//           isTerminal = true;
//           id = args[i + 1];
//           i++;
//           break;
//         case '--password':
//           password = args[i + 1];
//           i++;
//           break;
//         default:
//           break;
//       }
//     }
//     if (id != null) {
//       connect(context, id,
//           isFileTransfer: isFileTransfer,
//           isViewCamera: isViewCamera,
//           isTerminal: isTerminal,
//           password: password);
//     }
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_hbb/mobile/pages/settings_page.dart';
import 'package:flutter_hbb/web/settings_page.dart';
import 'package:get/get.dart';
import '../../common.dart';
import '../../common/widgets/chat_page.dart';
import '../../models/platform_model.dart';
import '../../models/state_model.dart';
import 'connection_page.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/server_model.dart';

abstract class PageShape extends Widget {
  final String title = "";
  final Widget icon = Icon(null);
  final List<Widget> appBarActions = [];
}

class HomePage extends StatefulWidget {
  static final homeKey = GlobalKey<HomePageState>();

  HomePage() : super(key: homeKey);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  var _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;
  final List<PageTab> _pages = [];
  int _chatPageTabIndex = -1;
  bool get isChatPageCurrentTab => isAndroid
      ? _selectedIndex == _chatPageTabIndex
      : false; // change this when ios have chat page

  void refreshPages() {
    setState(() {
      initPages();
    });
  }

  @override
  void initState() {
    super.initState();
    initPages();
  }

  void initPages() {
    _pages.clear();
    // Remover a página de conexão (ConnectionPage) para ocultar funcionalidade de conectar a outros PCs
    // if (!bind.isIncomingOnly()) {
    //   _pages.add(ConnectionPage(
    //     appBarActions: [],
    //   ));
    // }

    // Adicionar página personalizada como primeira aba
    _pages.add(PageTab(
      page: CustomHomePage(),
      title: "Início",
      icon: Icon(Icons.home),
    ));

    if (isAndroid && !bind.isOutgoingOnly()) {
      _chatPageTabIndex = _pages.length;
      _pages.add(PageTab(
        page: ChatPage(type: ChatPageType.mobileMain),
        title: "Chat",
        icon: Icon(Icons.chat),
      ));
    }
    _pages.add(PageTab(
      page: SettingsPage(),
      title: "Configurações",
      icon: Icon(Icons.settings),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: _selectedIndex == 0,
        onPopInvoked: (didPop) {
          if (!didPop && _selectedIndex != 0) {
            setState(() {
              _selectedIndex = 0;
            });
          }
        },
        child: Scaffold(
          // backgroundColor: MyTheme.grayBg,
          appBar: AppBar(
            centerTitle: true,
            title: appTitle(),
            actions: _pages.elementAt(_selectedIndex).appBarActions,
          ),
          bottomNavigationBar: BottomNavigationBar(
            key: navigationBarKey,
            items: _pages
                .map((page) =>
                    BottomNavigationBarItem(icon: page.icon, label: page.title))
                .toList(),
            currentIndex: _selectedIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: MyTheme.accent, //
            unselectedItemColor: MyTheme.darkGray,
            onTap: (index) => setState(() {
              // close chat overlay when go chat page
              if (_selectedIndex != index) {
                _selectedIndex = index;
                if (isChatPageCurrentTab) {
                  gFFI.chatModel.hideChatIconOverlay();
                  gFFI.chatModel.hideChatWindowOverlay();
                  gFFI.chatModel.mobileClearClientUnread(
                      gFFI.chatModel.currentKey.connId);
                }
              }
            }),
          ),
          body: _pages.elementAt(_selectedIndex).page,
        ));
  }

  Widget appTitle() {
    final currentUser = gFFI.chatModel.currentUser;
    final currentKey = gFFI.chatModel.currentKey;
    if (isChatPageCurrentTab &&
        currentUser != null &&
        currentKey.peerId.isNotEmpty) {
      final connected =
          gFFI.serverModel.clients.any((e) => e.id == currentKey.connId);
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Tooltip(
            message: currentKey.isOut
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
                  Text(
                    "${currentUser.firstName}   ${currentUser.id}",
                  ),
                  if (connected)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromARGB(255, 133, 246, 199)),
                    ).marginSymmetric(horizontal: 2),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return Text(bind.mainGetAppNameSync());
  }
}

// Nova página personalizada para mobile
class CustomHomePage extends StatelessWidget {
  final String title = "Início";
  final Widget icon = Icon(Icons.home);
  final List<Widget> appBarActions = [];

  @override
  Widget build(BuildContext context) {
    return CustomMobileLayout();
  }
}

class CustomMobileLayout extends StatefulWidget {
  @override
  CustomMobileLayoutState createState() => CustomMobileLayoutState();
}

class CustomMobileLayoutState extends State<CustomMobileLayout> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),

          // Logo da empresa
          buildCustomLogo(),

          SizedBox(height: 30),

          // ID do Servidor - Card mobile
          buildMobileIDCard(context),

          SizedBox(height: 16),

          // Senha - Card mobile
          buildMobilePasswordCard(context),

          SizedBox(height: 20),

          // Status do serviço
          if (bind.isIncomingOnly()) buildOnlineStatusWidget(),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget buildOnlineStatusWidget() {
    return ChangeNotifierProvider.value(
      value: gFFI.serverModel,
      child: Consumer<ServerModel>(
        builder: (context, model, child) {
          final bool isConnected = model.connectStatus == true ||
              model.connectStatus == 1 ||
              model.connectStatus == 'connected';
          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isConnected ? Colors.green : Colors.red,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.error,
                  color: isConnected ? Colors.green : Colors.red,
                ),
                SizedBox(width: 8),
                Text(
                  isConnected
                      ? translate("Service is running")
                      : translate("Service not running"),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildCustomLogo() {
    return Column(
      children: [
        // Logo da empresa
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/sua_empresa_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback para logo em texto caso a imagem não exista
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1BA3D4), Color(0xFF0F7BA8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.settings,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        SizedBox(height: 16),

        // Nome da empresa
        Text(
          'de Bruin Sistemas',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 8),

        // Slogan
        Text(
          'Suporte Técnico Remoto',
          style: TextStyle(
            fontSize: 14,
            color:
                Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget buildMobileIDCard(BuildContext context) {
    final model = gFFI.serverModel;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  translate("ID"),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, color: MyTheme.accent),
                  onPressed: () {
                    // Abrir configurações - você pode implementar conforme necessário
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: model.serverId.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(translate("Copied")),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: MyTheme.accent, width: 2),
                ),
                child: Center(
                  child: Text(
                    model.serverId.text,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              translate("Toque para copiar"),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMobilePasswordCard(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: gFFI.serverModel,
      child: Consumer<ServerModel>(
        builder: (context, model, child) {
          final textColor = Theme.of(context).textTheme.titleLarge?.color;
          final showOneTime = (model.approveMode != 'click') &&
              (model.verificationMethod != 'permanent');

          return Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    translate("One-time Password"),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: MyTheme.accent, width: 2),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (showOneTime) {
                                Clipboard.setData(ClipboardData(
                                    text: model.serverPasswd.text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(translate("Copied")),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: Center(
                              child: Text(
                                model.serverPasswd.text,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (showOneTime)
                          IconButton(
                            icon: Icon(Icons.refresh,
                                color: MyTheme.accent, size: 24),
                            onPressed: () => bind.mainUpdateTemporaryPassword(),
                            tooltip: translate('Refresh Password'),
                          ),
                        if (!bind.isDisableSettings())
                          IconButton(
                            icon: Icon(Icons.edit,
                                color: MyTheme.accent, size: 24),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SettingsPage()),
                              );
                            },
                            tooltip: translate('Change Password'),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    translate("Toque para copiar"),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class WebHomePage extends StatelessWidget {
  final connectionPage =
      ConnectionPage(appBarActions: <Widget>[const WebSettingsPage()]);

  @override
  Widget build(BuildContext context) {
    stateGlobal.isInMainPage = true;
    handleUnilink(context);
    return Scaffold(
      // backgroundColor: MyTheme.grayBg,
      appBar: AppBar(
        centerTitle: true,
        title: Text("${bind.mainGetAppNameSync()} (Preview)"),
        actions: connectionPage.appBarActions,
      ),
      body: connectionPage,
    );
  }

  handleUnilink(BuildContext context) {
    if (webInitialLink.isEmpty) {
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
    final args = urlLinkToCmdArgs(uri);
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
        case '--password':
          password = args[i + 1];
          i++;
          break;
        default:
          break;
      }
    }
    if (id != null) {
      connect(context, id,
          isFileTransfer: isFileTransfer,
          isViewCamera: isViewCamera,
          isTerminal: isTerminal,
          password: password);
    }
  }
}

class PageTab {
  final Widget page;
  final String title;
  final Widget icon;
  final List<Widget> appBarActions;

  PageTab({
    required this.page,
    required this.title,
    required this.icon,
    this.appBarActions = const [],
  });
}
