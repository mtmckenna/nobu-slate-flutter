# No Budget Slate

A dead-simple film/video digital slate for iOS and iPad — a Flutter rebuild of
the original [nobu-slate](https://github.com/mtmckenna/nobu-slate-2) (React
Native, 2018), modernized so it builds against current Xcode / iOS and ships as
an update to the existing App Store listing.

**Site:** http://www.mtmckenna.com/nobu-slate-flutter/

## What it does

Scene, take, audio-file, and audio-channel labels on one landscape screen, plus
a live date/time readout. Swipe horizontally anywhere and the screen flashes
red → green while playing a two-beep cadence — a frame-accurate reference an
editor uses to sync audio to picture in post.

- **Tap** any field to edit it (full-screen text entry).
- **Swipe up/down** on Scene / Take / Audio File to increment / decrement
  (numbers floor at 1; trailing letters walk A–Z; digit width is preserved,
  e.g. `001` → `002`).
- **Swipe horizontally** anywhere to mark — flash + beeps.
- All six fields persist locally and reload on launch.

## Stack

- Flutter (stable) / Dart 3
- `just_audio` (beep playback), `shared_preferences` (persistence),
  `wakelock_plus`
- Plain `StatefulWidget` + `setState` — the app is small by design
- iOS deployment target 13.0 · Android minSdk 21

## Running

```sh
flutter pub get
flutter run                       # pick a device, or:
flutter run -d <device-id> --release
```

Release mode is recommended for any audio-sync evaluation — the timing in debug
is not representative.

### iOS

CocoaPods is pinned via Bundler (`ios/Gemfile`). The iOS bundle id
(`com.mtmckenna.NoBuSlate`) matches the existing App Store record so builds
ship as an update, not a new app.

### Android

Release signing is wired conditionally: drop an `android/key.properties`
(gitignored) pointing at your upload keystore and release builds use it;
without it, builds fall back to debug signing so a fresh clone still builds.

## Tests

```sh
flutter test test/swipe_math_test.dart                    # unit
flutter test integration_test/app_test.dart -d <device>   # end-to-end
```

18 tests: swipe-math logic (number/letter/padding edge cases) and an
end-to-end flow (render, swipe inc/dec, tap-to-edit, whitespace trim,
persistence across restart).

## Project docs

Planning artifacts (PRD, product brief, spike findings) live in
`_bmad-output/planning-artifacts/`.

## License

See the original repository for license terms.
