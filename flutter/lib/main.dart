import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: InAppWebViewPage());
  }
}

class InAppWebViewPage extends StatefulWidget {
  @override
  _InAppWebViewPageState createState() => new _InAppWebViewPageState();
}

class _InAppWebViewPageState extends State<InAppWebViewPage> {
  InAppWebViewController? webView;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
          useShouldOverrideUrlLoading: true,
          mediaPlaybackRequiresUserGesture: false,
          javaScriptCanOpenWindowsAutomatically: true),
      android: AndroidInAppWebViewOptions(
          useHybridComposition: false,
          builtInZoomControls: false,
          supportMultipleWindows: true),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  InAppWebViewController? _webViewPopupController;

  DateTime? currentBackPressTime;

  @override
  void initState() {
    _handlePermission();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WillPopScope(
        onWillPop: onWillPop,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Container(
              child: Column(children: <Widget>[
            Expanded(
              child: Container(
                margin: EdgeInsets.only(top: 24),
                child: InAppWebView(
                    initialUrlRequest: URLRequest(
                        url: Uri.parse("https://clean-together-2021.web.app/")),
                    initialOptions: options,
                    androidOnGeolocationPermissionsShowPrompt:
                        (InAppWebViewController controller,
                            String origin) async {
                      return GeolocationPermissionShowPromptResponse(
                          origin: origin, allow: true, retain: true);
                    },
                    onWebViewCreated: (InAppWebViewController controller) {
                      webView = controller;
                    },
                    onCreateWindow: (controller, createWindowRequest) async {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            contentPadding: EdgeInsets.zero,
                            content: Container(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height,
                              child: InAppWebView(
                                // Setting the windowId property is important here!
                                windowId: createWindowRequest.windowId,
                                initialOptions: InAppWebViewGroupOptions(
                                  android: AndroidInAppWebViewOptions(
                                    thirdPartyCookiesEnabled: true,
                                  ),
                                  crossPlatform: InAppWebViewOptions(
                                      cacheEnabled: true,
                                      javaScriptEnabled: true,
                                      userAgent:
                                          "Mozilla/5.0 (Linux; Android 9; LG-H870 Build/PKQ1.190522.001) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/83.0.4103.106 Mobile Safari/537.36"),
                                ),
                                onWebViewCreated:
                                    (InAppWebViewController controller) {
                                  _webViewPopupController = controller;
                                },
                                onLoadStart: (controller, url) {
                                  print("onLoadStart popup $url");
                                },
                                onLoadStop: (controller, url) async {
                                  print("onLoadStop popup $url");
                                },
                                onCloseWindow: (controller) {
                                  // On Facebook Login, this event is called twice,
                                  // so here we check if we already popped the alert dialog context
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      );

                      return true;
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        print('[onLoadStart] url: $url');
                      });
                    },
                    onLoadStop: (controller, url) async {
                      setState(() {
                        print('[onLoadStop] url: $url');
                      });
                    }
                  ),
              ),
            ),
            ButtonBar(
              children: <Widget>[
                Row(children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      if (webView != null) {
                        webView?.goBack();
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward),
                    onPressed: () {
                      if (webView != null) {
                        webView?.goForward();
                      }
                    },
                  ),
                ]),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    if (webView != null) {
                      webView?.reload();
                    }
                  },
                ),
              ],
            ),
          ])),
        ),
      ),
    );
  }

  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.showToast(msg: "한 번 더 누르면 종료됩니다.");
      return Future.value(false);
    }
    return Future.value(true);
  }

  Future<bool> _handlePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    await Geolocator.requestPermission();

    return true;
  }
}
