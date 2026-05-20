# Settings page

**Status:** Draft · **Targets:** v3.1 (UI + flash-duration knob),
v3.2 if needed (configurable audio duration)

## Goal

Give users a small, discoverable surface to tune slate behavior — most
immediately the **mark flash duration** (so an editor shooting at 60fps
can pick a tighter blip than someone at 24fps), and a hook to add
further options without redesigning anything later.

The Sharper Mark and Full-screen Flash PRs ship sensible defaults
(50ms flash, 1000ms cadence). The Settings page makes them adjustable
for users with different needs, and is also the natural home for
follow-on options (color invert, single vs double beep, second-beep
delay, etc.).

## Access pattern

Slate UI is gesture-heavy (tap-edit, vertical swipe inc/dec, horizontal
swipe mark) and used in time-pressure on-set situations. Two competing
needs: **discoverability** (a feature no one finds is a feature that
doesn't exist) and **accidental-tap resistance** (during a take is the
worst possible time to open Settings).

Options considered:

| Pattern                                  | Discoverable? | Accidental-tap risk |
|------------------------------------------|---------------|---------------------|
| Long-press title bar (no visual)         | Low — must read release notes | Near-zero |
| Small gear icon in title bar, right edge | **High — users see it** | Low — small target, tap ≠ horizontal-drag, and the title bar is already tap-to-edit so no *new* surface area is made tappable |
| Floating gear in screen corner           | High | Risk of being under a horizontal-swipe path; overlaps home indicator on iPhone landscape |
| Two-finger tap anywhere                  | Low | Low, but iOS sometimes hijacks for accessibility |
| Shake the device                         | Low | Zero, but unusable for a slate held still on a table |

**Revised decision:** show a small **gear icon in the title bar's right
edge** (tap to open Settings). Tapping anywhere else on the title still
opens the title-edit screen — no behavior collision.

Why the title bar specifically:

- It's already a tap-target (tap = edit title), so the gear adds no
  region of the slate that wasn't already tappable.
- The title bar is ~11% of vertical height; a 40-dp gear at its right
  edge consumes < 5% of the bar's width and stays clear of the title
  text.
- Horizontal swipes for *mark* start from anywhere; tapping a small
  gear is gesturally distinct from sweeping across the screen, so the
  gesture arena resolves them cleanly.
- One small affordance is much cheaper to communicate than a hidden
  gesture nobody finds.

The gear renders in `colors.font` on the title bar's `colors.foreground`
with `opacity: 0.6` — a subtle affordance, not a CTA competing with the
title text.

```
┌─────────────────────────────────────────┐
│ Title                                ⚙  │
├─────────┬─────────┬─────────────────────┤
│  Scene  │  Take   │     Date / Time     │
...
```

**Accidental-open mitigation:** the gear is small (40-dp tap target
inside its own `GestureDetector` with `HitTestBehavior.opaque` so taps
are absorbed and don't bubble to the title's edit handler). If field
testing shows on-set users still hit it by accident, a 300 ms
tap-and-hold-to-confirm is a cheap follow-up.

## UI

Settings replaces the slate (same route-style swap pattern as
`EditScreen` — already established). Full-screen, black background,
white text matching the app's aesthetic.

Layout: a single scrollable column of controls. Each control has a
label and a value display.

```
┌─────────────────────────────────────┐
│ Settings                       Done │
├─────────────────────────────────────┤
│ Flash duration         [——●——] 50ms │
│                                     │
│ Mark cadence       [—————●—] 1000ms │
│                                     │
│ (later) Color scheme   [Normal ▾]   │
│ (later) Beep count     [• Two  ○ One] │
├─────────────────────────────────────┤
│              Restore defaults       │
└─────────────────────────────────────┘
```

Initial v3.1 scope: only the two sliders.

| Control            | Range            | Default | Stored as       |
|--------------------|------------------|---------|-----------------|
| Flash duration     | 30 – 500 ms      | 50 ms   | `int`           |
| Mark cadence       | 500 – 2000 ms    | 1000 ms | `int`           |

`Restore defaults` button writes the defaults back. `Done` (top-right)
returns to the slate.

## Data model & storage

New file `lib/models/settings.dart`:

```dart
class Settings {
  final int flashDurationMs;
  final int markIntervalMs;
  const Settings({this.flashDurationMs = 50, this.markIntervalMs = 1000});
  static const defaults = Settings();
  Settings copyWith({int? flashDurationMs, int? markIntervalMs}) => ...;
  factory Settings.fromJson(Map<String, dynamic> j) => ...;
  Map<String, dynamic> toJson() => ...;
}
```

New file `lib/services/settings_storage.dart` mirroring
`slate_storage.dart`. Uses a separate `SharedPreferences` key
`SLATE_SETTINGS` so saved slate values aren't entangled with config.

## Threading settings into the app

`main.dart` already owns `SlateData` state and the `_onMark` timing.
Add `Settings _settings = Settings.defaults` to the same `State`,
load it in `initState` (parallel to `loadSlateData`), and use it:

```dart
Future.delayed(Duration(milliseconds: _settings.flashDurationMs), () { ... });
Future.delayed(Duration(milliseconds: _settings.markIntervalMs),   () { ... });
```

No prop drilling — `main.dart` reads `_settings` directly when
scheduling mark steps. Settings page receives `_settings` + a
callback the same way `EditScreen` does.

## Configurable audio length — the hard part

The user explicitly raised this: *"think about how we can do the
audio if the length of the beep is configurable."* The reviewers'
"clap is too long" complaint partly came from the WAV files
themselves (~350ms each), not just the visual hold.

Four real options:

**A — Don't make audio length configurable (v3.1).**
Ship sliders that only affect the visual flash and the cadence
interval. Audio plays the existing 350ms WAVs whenever the cue
fires. Documents the asymmetry; simplest. **Recommended for v3.1.**

**B — Truncate playback via `just_audio` clipping.**
`just_audio` exposes `setClip(start, end)`. Set
`end = Duration(milliseconds: configuredLengthMs)` before each play.
Pros: no new asset, no new code path. Cons: cutting a 350ms WAV at
50ms mid-attack creates a hard pop (audible click) unless the WAV
has a clean fade-out at every cut point. The included beeps don't,
so this sounds bad below ~200ms.

**C — Bundle multiple WAV variants.**
Author short / medium / long WAVs (e.g. 50 / 150 / 350 ms, each with
a proper envelope), pick at runtime. Pros: best-sounding result.
Cons: more assets, fixed set of choices.

**D — Synthesize the beep at runtime.**
Generate a sine burst (e.g. 1 kHz, 5ms attack + sustain + 5ms decay)
as a PCM WAV byte buffer in Dart, expose it as a data URI or via
`just_audio.LockCachingAudioSource`. Pros: any duration, single
source of truth, no asset bloat. Cons: most code (~80 lines for a
clean WAV writer + envelope), small audible difference from the
recorded beep some users may notice as a regression.

**Recommendation:** ship **A** for v3.1 — flash duration is the
high-leverage change reviewers asked for first. If reviews after v3.1
still complain about audio sharpness, do **D** in v3.2 (cleanest
long-term) with a code-only change behind the existing slider.

## Backwards compatibility

- First launch after upgrade: no saved settings → defaults load →
  user sees identical behavior to v3.1 mark.
- The settings keys are append-only (new keys, never rename). Schema
  forward-compatible: any unknown field in saved JSON is ignored;
  any missing field falls back to default in `Settings.fromJson`.

## Test plan

Unit tests in `test/settings_test.dart` (new file):

1. `Settings.defaults` produces expected constants.
2. `copyWith` updates only specified fields.
3. `toJson`/`fromJson` round-trip preserves all fields.
4. `fromJson` with missing keys falls back to defaults.
5. `fromJson` with extra unknown keys doesn't throw.

Integration tests added to `integration_test/app_test.dart`:

1. **Tap gear icon → settings screen appears.** Assert
   `find.text('Settings')` and the two sliders. Also assert that
   tapping the *title text* (not the gear) still opens the title's
   edit screen, not Settings.
2. **Adjust flash slider → mark uses new duration.** Drag slider to
   200 ms, return to slate, fire mark, assert RED still showing at
   t=150ms (was white by then with the 50ms default).
3. **Settings persist across restart.** Set non-default values,
   relaunch app, assert sliders show stored values and a mark uses
   them.
4. **Restore defaults button works.** Tap it, sliders snap to defaults,
   save fires.

## Rollout

v3.1 release-notes line: *"New Settings page — tap the gear in the
title bar to adjust the mark flash duration and the cadence between
beeps for your preferred shooting framerate."*

If a v3.2 follows for audio synthesis, it's a code-only change with no
new UI — the existing flash slider grows to also control the synthesized
beep duration, transparently.
