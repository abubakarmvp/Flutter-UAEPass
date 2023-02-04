import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../uaepass.dart';
import 'configuration.dart';
import 'helper.dart';
import 'model/uaepass_login_result.dart';

class UaepassLoginView extends StatefulWidget {
  const UaepassLoginView({Key? key}) : super(key: key);

  @override
  State<UaepassLoginView> createState() => _UaepassLoginViewState();
}

class _UaepassLoginViewState extends State<UaepassLoginView> {
  InAppWebViewController? webViewController;
  String successUrl = '';
  PullToRefreshController? pullToRefreshController;
  double progress = 0;
  final MethodChannel channel =
      const MethodChannel('poc.deeplink.flutter.dev/channel1');

  @override
  void initState() {
    super.initState();
    channel.setMethodCallHandler((MethodCall call) async {
      final decoded = Uri.decodeFull(successUrl);
      webViewController?.loadUrl(
        urlRequest: URLRequest(
          url: Uri.parse(decoded),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: Helper.getLoginUrl(),
      builder: (context, AsyncSnapshot<String> snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF55C9B2),
            foregroundColor: Colors.black,
            title: const Text('UAE Pass'),
          ),
          body: InAppWebView(
            initialUrlRequest: URLRequest(url: Uri.parse(snapshot.data!)),
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                transparentBackground: true,
                useShouldOverrideUrlLoading: true,
                supportZoom: false,
              ),
            ),
            onWebViewCreated: (controller) async {
              // controller.clearCache();
              webViewController = controller;
            },
            onLoadStart: (controller, url) async {
              if (Configuration.app2App &&
                  url.toString().contains('uaepass://')) {
                final openUrl = Helper.getUaePassOpenUrl(url!);
                successUrl = openUrl.successUrl;

                await launchUrlString(openUrl.appUrl);
              }
            },
            shouldOverrideUrlLoading: (controller, uri) async {
              final url = uri.request.url.toString();
              if (url.contains('code=')) {
                final code = Uri.parse(url).queryParameters['code']!;
                Navigator.pop(context, code);

                // controller.onLogingComplete(code);
              } else if (url.contains('cancelled')) {
                if (Uaepass.instance.showMessages) {
                  ScaffoldMessenger.of(context)
                    ..removeCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('User cancelled login with UAE Pass'),
                      ),
                    );
                }

                Navigator.pop(context, UaePassResult.canceled);
              }
              return null;
            },
          ),
        );
      },
    );
  }
}
