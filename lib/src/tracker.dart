part of umami_tracker;

enum _CollectType {
  pageview('pageview'),
  event('event');

  final String value;

  const _CollectType(this.value);
}

class UmamiTracker {
  final String url;
  final String id;
  final String hostname;
  final String language;
  final String screenSize;
  final String userAgent;

  String? firstReferrer;

  UmamiTracker({
    required this.url,
    required this.id,
    required this.hostname,
    required this.language,
    required this.screenSize,
    required this.userAgent,
    this.firstReferrer,
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
    } else if (firstReferrer != null) {
      ref = firstReferrer!;
      firstReferrer = null;
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
