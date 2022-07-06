library umami_tracker;

import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:fk_user_agent/fk_user_agent.dart';
import 'package:flutter/widgets.dart';

part 'package:umami_tracker/src/tracker.dart';

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
/// - [firstReferrer]: Optionally provide a first referrer value that will be
/// attached to the first pageview without an explicit referrer. After that,
/// this value won't be used again. This could be useful to track the app store
/// or source from where the app was obtained, without sending the value
/// multiple times throughout the lifespan of the session.
///
Future<UmamiTracker> createUmamiTracker({
  required String url,
  required String id,
  required String hostname,
  String? firstReferrer,
}) async {
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  final size = Size(window.physicalSize.width, window.physicalSize.height);
  await FkUserAgent.init();

  return UmamiTracker(
    url: url,
    id: id,
    hostname: hostname,
    language: locale.toString(),
    screenSize: '${size.width.toInt()}x${size.height.toInt()}',
    userAgent: FkUserAgent.webViewUserAgent ?? '',
    firstReferrer: firstReferrer,
  );
}
