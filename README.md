# Umami Tracker

Umami tracker for Flutter.

[![style: lint](https://img.shields.io/badge/style-lint-4BC0F5.svg)](https://pub.dev/packages/lint)

This package tries to adapt the privacy-focused [Umami](https://umami.is/) analytics tool to use in a Flutter application.

## ⚠ State of this package ⚠

This package is in an experimental state, it's currently being tested in production as a secondary analytics tool. This package could be unstable and the API might change. Please use it with caution.

## How to use

You can track page views and events through an instance of `UmamiTracker`. In order to help in the construction of this object it is recommended to use the `createUmamiTracker()` method.

First, import this library:

```dart
import 'package:umami_tracker/umami_tracker.dart';
```

Make sure to invoke this before creating the tracker:

```dart
WidgetsFlutterBinding.ensureInitialized();
```

Create an instance of `UmamiTracker`. You can add this instance to your dependency injection graph or use any other mechanism to reuse in your code:

```dart
final umamiTracker = await createUmamiTracker(
  url: 'https://my.umami.instance',
  id: '9f65dd3f-f2be-4b27-8b58-d76f83510beb',
  hostname: 'com.my.app',
);
```

You can now track a screen view (page view):

```dart
await umamiTracker.trackScreenView('screen-name');
```

You can also track events:

```dart
await umamiTracker.trackEvent(
  eventType: 'event-type',
  eventValue: 'event-value', // Optionally define a value
  screenName: 'screen-name', // Optionally define a screen
);
```

## Other features

### First referrer

You can add a `firstReferrer` value in the `UmamiTracker` creation so that it is sent the first time you track a screen view. This can be useful for you to track for example which app store or source the user has downloaded the app from.

### Enable / disable

The tracking of screen views and events is enabled by default, but you can disable it when creating the `UmamiTracker` or via the `isEnabled` property. For example, you might want to prevent any event to be sent on debug builds:

```dart
final umamiTracker = await createUmamiTracker(
  url: 'https://my.umami.instance',
  id: '9f65dd3f-f2be-4b27-8b58-d76f83510beb',
  hostname: 'com.my.app',
  isEnabled: !kDebugMode,
);
```

## Known issues

- Each event is sent immediatelly when calling `trackScreenView()` or `trackEvent()`. If there is no internet connection the network request will fail and the event won't be sent.
- The device detection is not working properly, it tends to detect smartphones as tablets. This is due to the way Umami detects devices based, in part, of the screen resolution. Future work could be done to enhance this and send to Umami a certain resolution for a better detection.

## Contribution

If you want to contribute a small fix or patch feel free to submit a Pull Request. For enhancements or changes please open an issue in Github's issue tracker.