# Nobu Slate — Flutter Rebuild PRD + Eng Doc

**Status:** Draft, pre-spike
**Author:** Matt + Claude
**Date:** 2026-05-14
**Source repo:** `/Users/mckenna/workspace/nobu-slate-2` — https://github.com/mtmckenna/nobu-slate-2 (RN 0.53, last updated 2018)
**Target repo:** `/Users/mckenna/workspace/nobu-slate-flutter` (this directory)

---

## 1. Problem

The existing Nobu Slate iOS app is a React Native 0.53 codebase from 2018. It is too out-of-date to rebuild against current Xcode / iOS SDK, so we cannot resubmit to the App Store. The app itself is a film/video slate (digital clapperboard): scene/take values, an audio file label, two audio-channel labels, a date/time readout, and a "mark" action that flashes the screen and plays a two-beep cadence so an editor can sync audio to picture in post.

## 2. Goal

Ship a Flutter rebuild of Nobu Slate that:
- Is feature-parity with the existing app (no new features in v1).
- Builds against current Xcode / iOS 17+ / latest stable Flutter.
- Reuses the existing App Store listing (same bundle id, treated as an update).
- Submits and passes App Store review.
- Also ships to Android (Play Store) as a new listing. The original was iOS-only; the Flutter rebuild brings Android along since the platform cost is small. Treat Android as in-scope for v1, not a stretch goal — both stores should ship together.

**Critical correctness bar: audio/video sync.** This app exists to give editors a frame-accurate sync reference in post. The visual color flash (red at t=0, green at t=1000ms) and the corresponding audio beeps (`beep.wav` at t=0, `beep_final.wav` at t=1000ms) must fire together with sub-frame jitter — any perceptible drift between the on-screen flash and the beep defeats the entire purpose of the app. This is the single most important non-functional requirement and is the reason Spike S2 (audio cadence precision) is a go/no-go gate before implementation. If the chosen audio stack can't guarantee tight sync on iOS, we stop and re-evaluate the stack before writing M1.

## 3. Non-goals

- New features (theme picker, multiple slates, cloud sync, etc.) — out of scope for the v1 release on both platforms.
- ~~Tests at parity with the existing Jest + Detox suites — we'll add a thin smoke test only.~~ **Revised:** add a slim end-to-end suite via Flutter's built-in `integration_test` (one happy-path scenario covering all user flows) plus unit tests for `swipe_math.dart`. Total ~2–3 hours; payback is regression coverage as M4/M5/M6 evolve. The original Jest + Detox setup remains out of scope (not porting its structure, just its coverage intent).
- Android-specific UI affordances (back gesture handling beyond default, Material 3 theming, tablet-specific layouts) — ship the iPad layout 1:1 on Android tablets and accept the cosmetic gap for v1.

## 4. User-facing behavior (parity spec)

Sourced from reading `src/components/*` in the existing repo.

### 4.1 Layout (landscape-locked)

```
┌──────────────────────────────────────────────────────┐
│                       Title                          │  (tap to edit)
├────────────────┬────────────────┬────────────────────┤
│    Scene       │     Take       │                    │
│   (swipe ↕)    │   (swipe ↕)    │     Date / Time    │
├────────────────┴────────────────┤                    │
│         Audio File              │                    │
│         (swipe ↕)               │                    │
├─────────────────────────────────┼────────────────────┤
│       Audio Channel L           │   (audio channels  │
│       Audio Channel R           │    on the right)   │
└─────────────────────────────────┴────────────────────┘
```

(Actual flex ratios per `Slate.js`: top row `flex: 2`, bottom row `flex: 1`. Scene/Take share a `DoubleBox`, AudioFile alone in another DoubleBox.)

### 4.2 Gestures

- **Tap** on any field → opens a full-screen edit modal (`EditBox`) with a `TextInput`.
- **Vertical swipe up** on Scene / Take / Audio File → increments the value (see swipe math below).
- **Vertical swipe down** → decrements (floor of 1).
- **Horizontal swipe** *anywhere on the slate* → triggers `mark()` (the clapper action). The parent slate captures the horizontal gesture even if it starts on a child box.

Swipe math (`swipe-functions.js`): values are parsed as `(number)(optional uppercase letter)`. If a trailing letter is present, swipe moves through A–Z (clamped at A and Z). Otherwise swipe moves the integer (clamped at min 1, padded to original digit width). E.g. `"05" → "06"`, `"99A" → "99B"`, `"01Z" → "01Z"` (clamped).

### 4.3 Mark action

When `mark()` fires, with timing relative to t=0:
- t=0: play `beep.wav`. Set colors to `MARK_RED` (black bg, red fg, white text).
- t=500ms: revert to `MARK_WHITE` (white bg, black fg, white text).
- t=1000ms: set colors to `MARK_GREEN` (black bg, green fg, black text). Play `beep_final.wav`.
- t=1500ms: revert to `MARK_WHITE`. Re-enable mark.

While `countingDown` is true, additional marks are ignored.

### 4.4 Persistence

All six editable fields (`title`, `scene`, `take`, `audioFile`, `audioChannelL`, `audioChannelR`) are persisted to local storage on every edit. Initial values default to `'Title' / '1' / '1' / '001' / 'Lav' / 'Boom'`.

Implementation details from the original `slate-storage.js`:
- Single storage key `SLATE_PROPS` holds a JSON blob of all six fields.
- On app start, load and fall back to defaults if null.
- On every `updateValue`, `value.trim()` is applied before saving — leading/trailing whitespace is stripped silently.

### 4.7 Edit screen behavior

When any field is tapped, the slate is **replaced** by a full-screen edit view (not an overlay). The original `App.js` switches between `<Slate>` and `<EditBox>` based on a single `state.editing` field — not a modal overlay, a route-style swap.

The edit view contains a single `TextField` with:
- `autoFocus: true` — keyboard appears immediately.
- On submit (Done button on iOS keyboard / equivalent on Android): save the trimmed value, return to slate.
- The TextField shows the current value as its initial text so the user can edit-in-place.

### 4.8 AudioFile is free text, not a number

Despite the default `'001'` suggesting numeric, the AudioFile field accepts arbitrary text via the same edit modal as every other field. Swipe inc/dec applies the standard `\d+[A-Z]?` parsing — if the current value matches that shape, swipes work; otherwise swipes are a no-op and the user is expected to use tap-to-edit.

### 4.5 Date/time box

Live-updating once per second. Format: `YYYY-MM-DD` on one line, `HH:MM:SS` (24h) on the next.

### 4.6 Text sizing

Every label and value uses `adjustsFontSizeToFit + numberOfLines: 1 + fontSize: 1000` — i.e. text fills the box as large as possible while staying on one line. This is the defining visual of the app and must be replicated faithfully.

## 5. Technical approach

### 5.1 Stack

- **Flutter** stable (latest at install time; expected 3.24+).
- **Dart** 3.x.
- **iOS deployment target:** 13.0 (Flutter's current minimum).
- **Android minSdk:** 21 (Android 5.0; Flutter's current minimum). targetSdk: latest (currently 35).
- **State management:** plain `StatefulWidget` + `setState`. App is too small to justify Riverpod/Bloc.
- **Package choices** (pending spike validation):
  - Audio: `just_audio` (preferred for preload + low first-play latency) — fallback `audioplayers`. Both support iOS + Android; Android path uses ExoPlayer.
  - Storage: `shared_preferences`.
  - Orientation lock: `SystemChrome.setPreferredOrientations` + per-platform manifest (`UISupportedInterfaceOrientations` in `Info.plist` for iOS, `android:screenOrientation="landscape"` on the activity in `AndroidManifest.xml`).
  - Text autosizing: `FittedBox` first; `auto_size_text` if FittedBox layout proves fiddly with the label+value combos.
  - Error reporting: `sentry_flutter` (optional; the original used Bugsnag, which is fine too — picking Sentry for active maintenance).
  - Wakelock (keep screen on during shoots): `wakelock_plus` (both platforms).

### 5.2 Code structure

```
lib/
  main.dart                 # MyApp + orientation lock + storage bootstrap
  models/
    slate_data.dart         # data class + JSON serialization
    colors.dart             # MARK_WHITE / MARK_RED / MARK_GREEN
  services/
    beeper.dart             # preload + play beep / beep_final
    slate_storage.dart      # shared_preferences wrapper
    swipe_math.dart         # pure Dart port of swipe-functions.js
  widgets/
    slate_screen.dart       # top-level Slate (handles mark gesture)
    edit_screen.dart        # full-screen TextField editor
    box.dart                # labeled container
    box_with_swipe.dart     # vertical-swipe-aware box for Scene/Take/AudioFile
    double_box.dart
    date_time_box.dart
    audio_channels_box.dart
    title_bar.dart
    fitted_value.dart       # FittedBox wrapper used everywhere
assets/
  audio/
    beep.wav
    beep_final.wav
  app-icon-1024x1024.png
```

### 5.3 Mapping table (RN → Flutter)

| RN concept | Flutter equivalent |
|---|---|
| `View` + `flex` | `Column` / `Row` + `Expanded` |
| `StyleSheet.create` | inline widget properties / `ThemeData` |
| `PanResponder` (parent horizontal) | custom `HorizontalDragGestureRecognizer` via `RawGestureDetector` (see spike S1) |
| `PanResponder` (child vertical) | `GestureDetector(onVerticalDragEnd: …)` |
| `Text` + `adjustsFontSizeToFit` | `FittedBox(fit: BoxFit.contain, child: Text(…))` |
| `AsyncStorage` | `shared_preferences` |
| `react-native-sound` | `just_audio` |
| `react-native-orientation` | `SystemChrome.setPreferredOrientations` |
| `setTimeout` | `Future.delayed` |
| `setInterval` | `Timer.periodic` |
| `left-pad` | `String.padLeft` (Dart built-in) |
| `bugsnag-react-native` | `sentry_flutter` (optional) |

### 5.4 Open risks (drive the spikes)

1. **Nested gesture handling.** The parent slate must win horizontal swipes even when they start on a child box, while the children win vertical swipes. Flutter's gesture arena needs explicit configuration to mimic RN's `onMoveShouldSetPanResponderCapture` behavior. **→ Spike S1.**
2. **Audio playback latency / sync precision.** The whole point of the app is frame-accurate-ish audio cues. Need to confirm `just_audio` (or `audioplayers`) can play two preloaded WAVs 500ms apart with sub-50ms jitter on iOS. **→ Spike S2.**
3. **Auto-sized text layout.** `FittedBox` scales the rendered widget, not the font value. The existing layout has a small label inside each box plus a large value; reproducing the visual hierarchy may need flex tweaks or `auto_size_text`. **→ Spike S3.**
4. **Bundle id reuse.** Need to confirm the existing App Store record's bundle id (from `ios/nobuslate.xcodeproj`) can be reused as the Flutter `CFBundleIdentifier`. Low risk but worth verifying before submission. **→ Out-of-band check, not a spike.**

---

## 6. Spike plan

Each spike is a small, throwaway Flutter app (or dart_test) that answers one of the questions in 5.4. Output for each: a one-paragraph finding + a code snippet folded back into this doc.

### Spike S1 — Nested gesture arena
**Question:** Can a parent widget win horizontal swipes that start inside a child while the child still wins vertical swipes?
**Method:** Build a screen with one outer `Container` (parent) and one inner `Container` (child). Parent listens for horizontal drags, child for vertical. Print which one fires for each gesture. Try three implementations:
  (a) Nested `GestureDetector` — naive.
  (b) `RawGestureDetector` on parent with `HorizontalDragGestureRecognizer`, nested `GestureDetector` on child with `onVerticalDragEnd`.
  (c) Custom recognizer that wins only if the drag's primary axis matches.
**Success:** A configuration exists where horizontal-on-child fires the parent and vertical-on-child fires the child, with no double-fires.

### Spike S2 — Audio cadence precision
**Question:** Can we preload two WAVs and play them 500ms apart, with cadence at least as tight as the existing RN app on the same device?

**Method:** Two parts.
1. *Dart-side timing sanity check.* Minimal Flutter app with a button. On press: `await player1.play()`, schedule `Future.delayed(500ms, () => player2.play())`. Repeat 20 times, log timestamps of actual playback callbacks vs. requested. Try `just_audio` first; fall back to `audioplayers` only if `just_audio` is clearly drifting.
2. *A/B ear test vs. the existing RN app.* Install both the existing Nobu Slate (TestFlight build or local build of `nobu-slate-2`) and the spike app on the same iPad. Alternate marks between them. Listen on the iPad's built-in speaker, then again with AirPods. The existing app is the ground truth — anything that sounds as tight or tighter is shippable.

**Success:**
- Dart-side log shows mean offset within ±30ms of the 500ms target across 20 marks (loose bound — the ear test is the real gate).
- Cold-start first mark sounds clean (no audible glitch, no dropped first beep). Test: kill the app, launch, mark immediately, 5 times.
- A/B test: new app sounds at least as tight as the existing RN app to the naked ear, on both built-in speaker and AirPods.

**Go/no-go gate** — if the new app sounds worse than the existing one, do not proceed to M1 with the chosen audio stack.

### Spike S3 — FittedBox text layout
**Question:** Can we reproduce the RN `adjustsFontSizeToFit` look — label + giant value inside a flex container, both auto-shrinking — with `FittedBox` alone, or do we need `auto_size_text`?
**Method:** Build one `Box` widget that mirrors `src/components/Box.js`: top label (flex 0.15) + child area (flex 1). Test with values of varying length (`"1"`, `"99Z"`, `"Audio Channel L"`).
**Success:** Visual output matches a screenshot from the running RN app side-by-side.

---

## 7. Milestones (post-spike)

1. **M1 — Scaffolding (½ day).** `flutter create` for both platforms, set iOS bundle id + Android applicationId, copy audio assets + icon, configure landscape lock in `Info.plist` *and* `AndroidManifest.xml`, smoke screen.
2. **M2 — Static slate (1 day).** All boxes render with hardcoded data. No gestures. Pixel-match against screenshots on both an iPad and an Android tablet.
3. **M3 — Gestures (½ day).** Wire S1 result into `BoxWithSwipe` and `SlateScreen`. Verify scene/take/audio-file swipes and parent mark gesture on both platforms.
4. **M4 — Mark action + audio (½ day).** Wire S2 result into `Beeper`. Verify color flashes and audio cadence on physical iPad and physical Android device. This is where the deferred S2 hardware ear test happens — if either platform sounds wrong, fall back to the concatenated-buffer approach before moving on.
5. **M5 — Edit screen + persistence (½ day).** `EditScreen` text field; `shared_preferences` save on done, load on boot.
6. **M6 — Icon, splash, store metadata (1 day).** `flutter_launcher_icons` for both. iOS: `PrivacyInfo.xcprivacy` privacy manifest (required since 2024), `Info.plist` polish. Android: adaptive icon, store screenshots, `build.gradle` versioning, app signing setup.
7. **M6.5 — Tests (½ day).** Unit tests for `swipe_math.dart` (7+ assertions covering number, letter, padding, edge cases). One `integration_test` scenario covering all user flows end-to-end (renders, tap-to-edit each field, swipe inc/dec, horizontal-swipe-mark, persistence across restart). Not blocking M7 but should land before final submission.
8. **M7 — TestFlight + internal Play track + submissions (variable).** iOS: archive, upload to TestFlight, internal test on physical iPad, submit. Android: build app bundle, upload to Play Console internal testing track, internal test on a physical Android tablet, submit for review.

Total estimate: **4.5–5.5 working days** assuming spikes don't reveal a deal-breaker (was 3–4 for iOS-only; +½ to 1 day for Android-specific store work, packaging, and device testing; +½ day for the test suite).

---

## 8. Spike findings

*(To be filled in after running the spikes. Format: one paragraph per spike + key code snippet + decision.)*

### S1 — Nested gesture arena
TBD.

### S2 — Audio cadence precision
**Status:** Provisional pass — proceeding to M1. Tighter hardware ear test deferred to post-implementation; if real-device sync turns out to be unacceptable, fall back to a single concatenated buffer (beep + 1000ms silence + beep_final baked into one WAV, played once) — option (3) in the audio-fallback list. That alternative is cheap to swap in and eliminates inter-beep scheduling entirely.

Spike app (`/Users/mckenna/workspace/slate_spike_s2`) built and ran on iPad Air 11-inch M4 simulator (iOS 26.5) using `just_audio ^0.9.42`. Two WAVs preloaded in `initState` via `setAsset`. On tap: red flash + `beep.wav` at t=0, white at t=500ms, green flash + `beep_final.wav` at t=1000ms, white + re-enable at t=1500ms. Cadence sounded clean and tight on simulator audio (Mac CoreAudio path). No cold-start glitches observed across casual marking.

Simulator audio is not authoritative — Mac CoreAudio differs from iPad audio pipeline, and Android (ExoPlayer) is a separate pipeline again. The hardware ear test still wants doing eventually, just not as a blocking gate.

**Decision:** proceed with `just_audio` on both platforms.

**Minor finding:** `SystemChrome.setPreferredOrientations([landscape...])` logs a warning on iPadOS 26 simulator ("current windowing mode does not allow for programmatic changes to interface orientation") because iPad multitasking ignores the runtime call. The fix for parity is to declare supported orientations in `Info.plist` (`UISupportedInterfaceOrientations` = LandscapeLeft + LandscapeRight only) on iOS, plus `android:screenOrientation="landscape"` on `MainActivity` in `AndroidManifest.xml`. Carry into M1.

### S3 — FittedBox text layout
TBD.

---

## 9. Open questions

- **Bundle id (iOS).** What is the existing App Store bundle id? (Need to read `ios/nobuslate.xcodeproj/project.pbxproj` and confirm with App Store Connect.)
- **Version number.** Last shipped (per `nobu-slate-2` repo, commit `fecc673`, 2018-05-19): `CFBundleShortVersionString = 2.1`. The Flutter rebuild is a major rewrite, so bump the major version. Flutter `pubspec.yaml` `version:` for the rebuild's first submission: **`3.0.0+1`**. Bump the build number (`+N`) on TestFlight / Play internal-track iterations during M7; bump the version-name only on store-visible release submissions.
- **App Store Connect access.** Matt has it; no blocker.
- **Apple Developer account state.** Active and paid? Worth confirming before M7.
- **Privacy manifest (iOS).** App doesn't make network calls or access protected APIs beyond audio playback, so the manifest will be minimal — confirm during M6.
- **Google Play Console account.** Does Matt have an active Play Console developer account? One-time $25 fee if not. Resolve before M7.
- **Android applicationId.** Brand-new listing; pick a fresh id (e.g. `com.mtmckenna.nobuslate`). Decide before M1.
- **Android signing keystore.** Need to generate a new upload key and configure `key.properties` + Gradle signing config. Standard, but worth doing in M1 not M7.
- **Data safety form (Play Store).** Play requires a data-safety declaration even for apps with no data collection. Trivial in our case (no collection, no sharing) but must be filled in during M6.
- **Test device matrix.** Matt has: iPad (real, primary layout truth), iPhone (real, secondary iOS audio + cramped-layout check), Android phone (real, ExoPlayer audio cadence + build verification). No physical Android tablet; layout on Android tablets is verified via an **Android tablet simulator** (e.g. Pixel Tablet in Android Studio AVD Manager). Phone-sized layouts on either OS are not gated for v1 — see §3 Non-goals.
