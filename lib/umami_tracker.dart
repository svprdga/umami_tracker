library umami_tracker;

import 'dart:ui';

import 'package:devicelocale/devicelocale.dart';
import 'package:dio/dio.dart';
import 'package:fk_user_agent/fk_user_agent.dart';
import 'package:flutter/widgets.dart';

// enum _CollectType {
//   pageview('pageview'),
//   event('event');
//
//   final String type;
//
//   const _CollectType(this.type);
// }

Future<UmamiTracker> createUmamiTracker({
  required String url,
  required String id,
  required String hostname,
}) async {
  final language = await Devicelocale.currentLocale ?? 'en_US';
  final size = Size(window.physicalSize.width, window.physicalSize.height);
  await FkUserAgent.init();

  return UmamiTracker(
    url: url,
    id: id,
    hostname: hostname,
    language: language,
    screenSize: '${size.width.toInt()}x${size.height.toInt()}',
    userAgent: FkUserAgent.webViewUserAgent ?? '',
  );
}

class UmamiTracker {
  final String url;
  final String id;
  final String hostname;
  final String language;
  final String screenSize;
  final String userAgent;

  /// Constructs a new UmamiTracker to start tracking pageviews and events.
  /// </br>
  /// Required parameters:
  /// - [url]: Remote server address of the Umami instance,
  /// example: https://my.analytics.server
  /// - [id]: Id of the configured site. You can found it within the
  /// tracking code. Example: 9f65dd3f-f2be-4b27-8b58-d76f83510beb
  /// - [hostname]: The name of the configured host. You should use the value
  /// that you set when configuring the site in the Umami dashboard.
  /// Example: com.my.app
  ///
  /// [TODO]: REVISAR *********************
  UmamiTracker({
    required this.url,
    required this.id,
    required this.hostname,
    required this.language,
    required this.screenSize,
    required this.userAgent,
  });

  Future<void> trackScreenView(String screenName) async {
    await _collectPageView(path: screenName);
  }

  Future<void> _collectPageView({
    String path = '/',
    String referrer = '',
  }) async {
    final payload = {
      'website': id,
      'url': path,
      'referrer': referrer,
      'hostname': hostname,
      'language': language,
      'screen': screenSize,
    };

    try {
      await Dio().post(
        '$url/api/collect',
        options: Options(
          headers: {
            'User-Agent': userAgent,
          },
        ),
        data: {
          'payload': payload,
          'type': 'pageview',
        },
      );
    } on DioError catch (e) {
      debugPrint('Error while trying to collect data: $e');
    }
  }
}
