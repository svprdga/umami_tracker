library umami_tracker;

import 'dart:ui';

import 'package:devicelocale/devicelocale.dart';
import 'package:dio/dio.dart';
import 'package:fk_user_agent/fk_user_agent.dart';
import 'package:flutter/widgets.dart';

enum _CollectType {
  pageview('pageview'),
  event('event');

  final String value;

  const _CollectType(this.value);
}

/// Constructs a new UmamiTracker to start tracking pageviews and events.
///
///
/// This function will fetch the language of the user's device and the
/// size of the screen. Also it will call [FkUserAgent.init()] which is
/// needed for obtaining the user agent. Then it will return a [UmamiTracker]
/// with all the values provided.
///
///
/// Required parameters:
/// - [url]: Remote server address of the Umami instance,
/// example: https://my.analytics.server
/// - [id]: Id of the configured site. You can found it within the
/// tracking code. Example: 9f65dd3f-f2be-4b27-8b58-d76f83510beb
/// - [hostname]: The name of the configured host. You should use the value
/// that you set when configuring the site in the Umami dashboard.
/// Example: com.my.app
/// - [permanentReferrer]: If provided, it will be used as a referrer for all
/// pageviews that doesn't include an explicit referrer. This could be used to
/// track the app store or source from where the app was obtained.
///
Future<UmamiTracker> createUmamiTracker({
  required String url,
  required String id,
  required String hostname,
  String? permanentReferrer,
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
    permanentReferrer: permanentReferrer,
  );
}

class UmamiTracker {
  final String url;
  final String id;
  final String hostname;
  final String language;
  final String screenSize;
  final String userAgent;
  final String? permanentReferrer;

  UmamiTracker({
    required this.url,
    required this.id,
    required this.hostname,
    required this.language,
    required this.screenSize,
    required this.userAgent,
    this.permanentReferrer,
  });

  /// Send a pageview using the [screenName]. If [referrer] is provided
  /// it will be used overriding any permanent value.
  Future<void> trackScreenView(
    String screenName, {
    String? referrer,
  }) async {
    await _collectPageView(path: screenName, referrer: referrer);
  }

  /// Send an event with the specified [eventType]. You can optionally provide
  /// an [eventValue] and/or a [screenName] to attach to the event.
  Future<void> trackEvent({
    required String eventType,
    String? eventValue,
    String? screenName,
  }) async {
    await _collectEvent(
      eventType: eventType,
      eventValue: eventValue,
      path: screenName,
    );
  }

  Future<void> _collectPageView({
    String? path,
    String? referrer,
  }) async {
    final payload = {
      'website': id,
      'url': path ?? '/',
      'referrer': _getReferrer(referrer),
      'hostname': hostname,
      'language': language,
      'screen': screenSize,
    };

    await _collect(payload: payload, type: _CollectType.pageview);
  }

  Future<void> _collectEvent({
    required String eventType,
    String? eventValue,
    String? path,
  }) async {
    final payload = {
      'website': id,
      'url': path ?? '/',
      'event_type': eventType,
      'event_value': eventValue ?? '',
      'hostname': hostname,
      'language': language,
      'screen': screenSize,
    };

    await _collect(payload: payload, type: _CollectType.event);
  }

  String _getReferrer(String? inputRef) {
    String ref;
    if (inputRef != null) {
      ref = inputRef;
    } else if (permanentReferrer != null) {
      ref = permanentReferrer!;
    } else {
      ref = '';
    }

    if (ref.isNotEmpty) {
      try {
        final uri = Uri.parse(ref);
        if (!uri.isAbsolute) {
          throw Exception();
        }
      } catch (_) {
        ref = 'https://$ref';
      }
    }

    return ref;
  }

  Future<void> _collect({
    required Map<String, dynamic> payload,
    required _CollectType type,
  }) async {
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
          'type': type.value,
        },
      );
    } on DioError catch (e) {
      debugPrint('Error while trying to collect data: $e');
    }
  }
}
