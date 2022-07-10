import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:umami_tracker/umami_tracker.dart';

import 'mocks.dart';

void main() {
  group('UmamiTracker -', () {
    const id = 'aa40d29b-c033-4c12-85cf-08b59e1a22df';
    const hostname = 'https://my.umami.instance';
    const language = 'en_US';
    const screenSize = '720x1280';
    const userAgent = 'User Agent Test';

    const screenName = 'TestScreen';
    const providedReferrer = 'FakeReferrer';
    const eventType = 'FakeEventType';
    const eventValue = 'FakeEventValue';

    late UmamiTracker tracker;

    late DioMock dio;
    final ResponseMock response = ResponseMock();

    setUp(() {
      dio = DioMock();

      tracker = UmamiTracker(
        dio: dio,
        id: id,
        hostname: hostname,
        language: language,
        screenSize: screenSize,
        userAgent: userAgent,
      );
    });

    void _prepareDioForResponse() {
      when(
        () => dio.post(
          '/api/collect',
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) => Future.value(response));
    }

    List _capture() {
      return verify(
        () => dio.post(
          captureAny(),
          options: captureAny(named: 'options'),
          data: captureAny(named: 'data'),
        ),
      ).captured;
    }

    void _verifyCollect({
      required String type,
      required String path,
      String? referrer,
      String? eventType,
      String? eventValue,
    }) {
      final captured = _capture();
      expect(captured.first, '/api/collect');

      final options = captured[1] as Options;
      expect(options.headers!['User-Agent'], userAgent);

      final data = captured[2] as Map<String, dynamic>;
      expect(data['type'], type);

      final payload = data['payload'] as Map<String, dynamic>;
      expect(payload['website'], id);
      expect(payload['url'], path);

      expect(payload['hostname'], hostname);
      expect(payload['language'], language);
      expect(payload['screen'], screenSize);

      if (type == 'pageview') {
        expect(payload['referrer'], referrer);
      } else {
        expect(payload['event_type'], eventType);
        expect(payload['event_value'], eventValue);
      }
    }

    group('when calling trackScreenView()', () {
      group('given only screen name is provided', () {
        test('should track the screen view', () async {
          _prepareDioForResponse();
          await tracker.trackScreenView(screenName);
          _verifyCollect(type: 'pageview', path: screenName, referrer: '');
        });
      });

      group('given screen name and referrer is provided', () {
        test('should track the screen view', () async {
          _prepareDioForResponse();
          await tracker.trackScreenView(screenName, referrer: providedReferrer);
          _verifyCollect(
            type: 'pageview',
            path: screenName,
            referrer: 'https://$providedReferrer',
          );
        });
      });
    });

    group('when calling trackEvent()', () {
      group('given only eventType is provided', () {
        test('should track the event', () async {
          _prepareDioForResponse();
          await tracker.trackEvent(eventType: eventType);
          _verifyCollect(
            type: 'event',
            path: '/',
            eventType: eventType,
            eventValue: '',
          );
        });
      });

      group('given eventType and eventValue is provided', () {
        test('should track the event', () async {
          _prepareDioForResponse();
          await tracker.trackEvent(
            eventType: eventType,
            eventValue: eventValue,
          );
          _verifyCollect(
            type: 'event',
            path: '/',
            eventType: eventType,
            eventValue: eventValue,
          );
        });
      });

      group('given eventType and screenName is provided', () {
        test('should track the event', () async {
          _prepareDioForResponse();
          await tracker.trackEvent(
            eventType: eventType,
            screenName: screenName,
          );
          _verifyCollect(
            type: 'event',
            path: screenName,
            eventType: eventType,
            eventValue: '',
          );
        });
      });
    });

    group('when firstReferrer is provided', () {
      test('should add firstReferrer value in the first screen view only',
          () async {
        const firstReferrer = 'FakeFirstReferrer';

        tracker = UmamiTracker(
          dio: dio,
          id: id,
          hostname: hostname,
          language: language,
          screenSize: screenSize,
          userAgent: userAgent,
          firstReferrer: firstReferrer,
        );

        _prepareDioForResponse();
        await tracker.trackScreenView(screenName);
        _verifyCollect(
          type: 'pageview',
          path: screenName,
          referrer: 'https://$firstReferrer',
        );

        // The next screen view should not contain the first referrer
        await tracker.trackScreenView(screenName);
        _verifyCollect(
          type: 'pageview',
          path: screenName,
          referrer: '',
        );
      });
    });

    group('when tracker is disabled', () {
      setUp(() {
        tracker = UmamiTracker(
          dio: dio,
          id: id,
          hostname: hostname,
          language: language,
          screenSize: screenSize,
          userAgent: userAgent,
          isEnabled: false,
        );
      });

      test('should not track screen views', () async {
        await tracker.trackScreenView(screenName);
        verifyNever(() => dio.post(any()));
      });

      test('should not track events', () async {
        await tracker.trackEvent(eventType: eventType);
        verifyNever(() => dio.post(any()));
      });
    });
  });
}
