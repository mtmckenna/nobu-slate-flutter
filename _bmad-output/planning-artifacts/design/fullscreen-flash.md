# Full-screen flash — flash the whole viewport, not just the boxes

**Status:** Draft · **Targets:** v3.1

## Problem

A 1★ review of the v2.0 update — the same visual model our rebuild
inherited — captured the issue:

> "the red / green flash only highlights within the borders — making it
> difficult for an editor to see the numbers clearly or sync the sound,
> which is kind of the point!" — *scoresofar, 1★ v2.0*

In our current implementation (`lib/widgets/slate_screen.dart` +
`lib/models/slate_colors.dart`):

- During a mark, the **box `foreground` color** becomes RED or GREEN.
- The **slate `background` color** stays BLACK (between/around boxes).
- The SafeArea insets (notch, home indicator) are also black.

Result: a sizable fraction of the visible viewport stays black during the
flash. From across a set or in peripheral vision the cue is muddier than
it needs to be.

## Diagnosis

`SlateColors` constants:

```dart
markRed   = bg=BLACK, fg=RED,   font=WHITE
markGreen = bg=BLACK, fg=GREEN, font=BLACK
markWhite = bg=WHITE, fg=BLACK, font=WHITE
```

A frame-accurate slate wants the *entire screen* to change color so
there's no ambiguity for the editor's eye or for an automated
sync tool processing the recording.

## Proposal

Change the mark color schemes so the slate background also flashes:

```dart
markRed   = bg=RED,   fg=RED,   font=WHITE
markGreen = bg=GREEN, fg=GREEN, font=BLACK
markWhite = bg=WHITE, fg=BLACK, font=WHITE   // unchanged
```

This makes the SafeArea margins, the inter-box gaps, and any letterbox
area all flash the same color as the box foregrounds. From a few feet
away (typical AC distance) the cue becomes an unambiguous full-screen
color change.

The box dividers visually vanish during the flash (foreground == bg)
— this is *intended*: the entire screen is one solid color for ~50ms,
maximum visual punch. Field values and labels remain visible because
`font` color contrasts the foreground (white on red, black on green).

## Alternatives considered

- **Full-screen overlay during the flash window.** Stack a translucent
  red/green `Container` over the slate via an `IndexedStack` or a
  conditional widget that takes over the screen for 50ms. More code,
  same visible result. Rejected — the color-scheme change is one-line.
- **Keep box borders visible by darkening foreground slightly.** Halves
  the visual impact. Rejected.
- **Animate the flash via a `ColorTween`** for a softer transition.
  Defeats the "sharp snap" the previous PR is built around. Rejected.

## Test plan

Adds to `integration_test/app_test.dart`:

1. **Slate background = RED during the red flash.** After firing the
   mark, pump 20ms, locate the root `Container` (via a new
   `ValueKey('slate-root')`), assert its `color == SlateColors.markRed.background`.
2. **Slate background = GREEN at t≈1010ms.** Same check, GREEN.
3. **Slate background = WHITE before/after.** Pre-mark and post-cadence,
   assert markWhite background.
4. **Field text still readable during flash.** Assert the Scene "1"
   `Text` is still in the widget tree (didn't get clobbered) during
   the red and green windows.

## Interaction with the Sharper Mark PR

Both PRs are sized for v3.1 and touch nearby code. Merge order:

1. **Sharper Mark first** (changes timing constants).
2. **Full-screen Flash second** (changes the color constants).

If they land in the opposite order the only conflict is the new
`ValueKey('slate-root')` — trivially resolved.

## Rollout

Ship together with the Sharper Mark PR as v3.1. Combined release-notes
line: *"The mark is now a sharp, single-frame full-screen flash — much
easier for editors and sync tools to land on the exact frame."*
