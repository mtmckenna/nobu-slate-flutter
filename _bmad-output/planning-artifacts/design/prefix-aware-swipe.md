# Prefix-aware swipe — increment the trailing number, not the whole field

**Status:** Draft · **Targets:** v3.1

## Problem

> "I wish it could recognize the number at the end of my audio file so
> I can type `mono.001` and swipe up and get `mono.002`. This would be
> nice just so I could get the exact name of the file for editing."
> — *Quinnthefilmmaker, 5★*

Real workflow: AC types the field recorder's actual filename pattern
(`mono.001`, `BWF_0042`, `WildTrack_A_007`) and wants swipe-to-increment
to bump just the number. Today our regex requires the whole field to be
digits + optional letter, so any prefix turns swipe into a no-op and the
user has to tap-edit + retype the whole string for every take.

## Diagnosis

`lib/services/swipe_math.dart`:

```dart
final _matchRe = RegExp(r'^(\d*)([A-Z]?)$');
```

This matches only:
- `1`, `99`, `001` (pure digits)
- `1A`, `99Z`, `01Z` (digits + trailing letter)

Anything with a prefix returns the input unchanged: `mono.001` → `mono.001`.

## Proposal

Detect the trailing `(\d+)([A-Z]?)` chunk anywhere in the string, keep
everything before it as a literal prefix, increment the matched chunk,
reassemble.

```dart
final _trailingRe = RegExp(r'^(.*?)(\d+)([A-Z]?)$');
```

Rewrite `swipeValue`:

```dart
String swipeValue(String oldValue, int direction) {
  final upper = oldValue.toUpperCase();
  final m = _trailingRe.firstMatch(upper);
  if (m == null) return oldValue;          // no trailing number → no-op
  final prefix    = m.group(1) ?? '';
  final numberStr = m.group(2)!;
  final letter    = m.group(3) ?? '';
  final width     = numberStr.length;
  final number    = int.tryParse(numberStr) ?? 1;

  if (letter.isNotEmpty) {
    return '$prefix$numberStr${_nextLetter(letter, direction)}';
  }
  final next = direction > 0 ? number + 1 : (number - 1).clamp(1, 1 << 30);
  return '$prefix${next.toString().padLeft(width, '0')}';
}
```

## Worked examples

| Input          | Up                | Down              |
|----------------|-------------------|-------------------|
| `1`            | `2`               | `1` (floor)       |
| `001`          | `002`             | `001`             |
| `99A`          | `99B`             | `99A` (A floor)   |
| `mono.001`     | `mono.002`        | `mono.001`        |
| `BWF_0042`     | `BWF_0043`        | `BWF_0041`        |
| `WildTrack_A_007` | `WildTrack_A_008` | `WildTrack_A_006` |
| `Scene7B`      | `Scene7C`         | `Scene7A`         |
| `intro`        | `intro` (no-op)   | `intro` (no-op)   |
| `7intro`       | `7intro` (no-op — trailing letters lowercase + no digit chunk after) | same |
| empty string   | empty (no-op)     | empty             |

The prefix is preserved verbatim (and uppercased — see "Caveats").
Letter clamps still apply (Z→Z up, A→A down). Number floor still 1.

## Caveats / behavior changes vs current

1. **Whole string still gets uppercased** before the match (carried
   over from current behavior — original RN did this for the alpha
   suffix to stay capitalized). Means `mono.001` → `MONO.002`. If
   that's unwanted, we can preserve case of the prefix and only
   uppercase the suffix letter. Open question.
2. **Numbers in the middle are still ignored.** `take_3_001` →
   prefix=`TAKE_3_`, number=`001`. Only the *trailing* digit run gets
   incremented. This matches user intuition (filenames almost always
   end in the take counter).
3. **A trailing single letter with no preceding digits** doesn't
   match (e.g. `abc` won't roll a→b). Same as current. The original
   feature was always "increment a number, optionally walk a letter."
   No regression here.

## Decision needed before implementation

- **Preserve original-case prefix?** I'd vote yes. One-line tweak:
  match on the original string with a case-insensitive flag for the
  trailing letter, then uppercase only the letter group.

## Test plan

Adds to `test/swipe_math_test.dart` (currently 10 assertions, all
green):

- prefix + plain digits inc/dec/floor (`mono.001`, `BWF_0042`)
- prefix + digits + letter (`Scene7B`, `Take_99A`)
- multi-segment prefix (`WildTrack_A_007`)
- empty string, whitespace-only, non-matching strings
- digit-width preservation across the prefix split
- letter Z/A clamp with a prefix
- case-preservation behavior (per decision above)

Existing 10 tests stay passing — the new regex is a strict superset
of the old behavior on the old test inputs.

Integration test in `integration_test/app_test.dart` unchanged
(swipes already covered); add one scenario for an edited prefix
audio-file value: tap audio-file → type `mono.001` → submit → swipe
up → assert `mono.002`.

## Rollout

Ships in v3.1 alongside the mark improvements. Release-notes line:
*"Swipe-to-increment now works on field-recorder filenames like
`mono.001` — increments the trailing number, preserves the prefix."*
