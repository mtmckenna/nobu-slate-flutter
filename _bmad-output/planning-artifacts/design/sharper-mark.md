# Sharper Mark — shorten the visual flash hold

**Status:** Draft · **Targets:** v3.1

## Problem

Multiple App Store reviews (across versions 1.1, 2.0, 2.1) say the mark
flash lasts too long, defeating the app's primary purpose:

> "The slating signals, both audio and visual, are far too long for this
> to be a syncing tool. The snap of a clapper board is a very quick sound
> that fits inside of a single video frame... If either the sound or
> visual cue lasts for multiple frames, then you don't know which frame
> to sync to." — *Robér, 2★*

> "The clap (both beep and flash) is too long and takes multiple frames
> of video, especially if you shoot at a higher frame rate. This makes
> synchronization of audio and video impossible." — *calincostian, 4★*

> "Would be appropriate to have sharp quickly decaying clap" — *surrealdog, 5★*

## Diagnosis

Current `_onMark` in `lib/main.dart` (carried over from the original RN
app for parity):

| t (ms) | event                          |
|-------:|--------------------------------|
|      0 | play `beep.wav`, color = RED   |
|    500 | color = WHITE                  |
|   1000 | play `beep_final.wav`, color = GREEN |
|   1500 | color = WHITE, re-enable mark  |

The 500ms color hold is **12 frames at 24fps, 30 frames at 60fps** — far
above the "single frame" reviewers ask for. The mark cadence interval
(t=0 vs t=1000ms) is the *sync signal* the editor pins to and should
stay 1000ms — that's the established cue everyone learned. What's wrong
is the *duration* the color is held at each peak.

## Proposal

Change the color flashes to ~50ms holds. Audio events stay at t=0 and
t=1000ms (those define sync). The full-screen flash improvement is a
separate PR; this one only tightens timing.

| t (ms) | event                          |
|-------:|--------------------------------|
|      0 | play `beep.wav`, color = RED   |
|     50 | color = WHITE                  |
|   1000 | play `beep_final.wav`, color = GREEN |
|   1050 | color = WHITE                  |
|   1100 | re-enable mark (countingDown=false) |

`50ms` ≈ 1.2 frames at 24fps, 3 frames at 60fps — visually a sharp blip.
Picked over `~42ms` (true 1 frame at 24fps) to leave a small margin for
Dart scheduler jitter on slower devices.

**Constants** in `lib/main.dart`:

```dart
const _flashDurationMs = 50;
const _markIntervalMs = 1000;        // gap between RED and GREEN
const _markCooldownMs = 100;         // after GREEN flash ends
```

(These become settings inputs in the Settings PR — for v3.1 they ship
as build-time defaults.)

## Out of scope

- **Audio sharpness.** `beep.wav` and `beep_final.wav` are themselves
  ~350ms each — sharpening *those* requires either re-recording with
  shorter samples, runtime tone synthesis, or bundling shorter
  variants. That work belongs in the Settings PR (which has to make a
  duration adjustable anyway). The visual fix here is a real,
  shippable improvement on its own; the audio fix follows.
- **Full-screen flash color** — separate PR.
- **Settings UI** — separate PR.

## Alternatives considered

- **30ms hold**: closer to true single-frame at 24fps, but more
  vulnerable to dropped frames being invisible to the user.
- **Match the WAV duration**: hold color for exactly as long as the
  beep audio plays. Couples visual to audio file length, makes future
  audio changes brittle. Rejected.
- **No hold at all**: flash one frame via a Ticker-driven render.
  Cleanest mathematically but overengineered for an app this small.

## Test plan

Adds to `integration_test/app_test.dart`:

1. **Mark RED is visible at t=0+small, then white by t=100ms.**
   After firing a horizontal swipe, pump 20ms and assert the slate
   background color is `SlateColors.markRed.background`. Pump to
   100ms and assert it's back to `SlateColors.markWhite.background`.
2. **Mark GREEN appears around t=1000ms.** Pump to t=1010ms, assert
   green; pump to t=1060ms, assert white.
3. **Re-mark blocked during cadence.** Fire two horizontal swipes
   ~50ms apart; second should not retrigger (assert mark count = 1
   via a test-injected callback).

Existing color-state assertion plumbing doesn't exist yet — small
helper added: `find.byKey(ValueKey('slate-root'))` exposes the root
Container so its `color` can be read in tests.

## Rollout

Bundled with the full-screen flash PR for v3.1. Single visible
change in the release notes: *"Mark flash is now a sharp, single-frame
blip so editors can pin to the exact sync frame."*
