# Product Brief: Nobu Slate (Flutter Rebuild)

**Status:** Draft, pre-spike
**Author:** Matt (with Claude)
**Date:** 2026-05-14
**Source PRD:** `PRD.md`

## Executive Summary

Nobu Slate is a film/video digital slate (clapperboard) for iOS — an editor's frame-accurate sync reference, not a content app. Scene/take/audio-file labels, a date/time readout, and a "mark" action that flashes the screen red→green while playing a two-beep cadence 500ms and 1000ms apart, giving editors a clean visual + audio cue to align picture and audio in post.

The original ships on the App Store today, but its 2018 React Native 0.53 codebase no longer builds against current Xcode/iOS SDKs, blocking any further updates or resubmission. Rather than patch a dead toolchain, we are rebuilding the app in Flutter at strict feature parity, reusing the existing App Store listing and bundle id so the rebuild ships as an update — not a new product. The bet is that a small, focused parity rewrite (3–4 working days of implementation behind three de-risking spikes) restores the app to a maintainable state for the next several years.

## The Problem

The app is a working tool — editors rely on its visual flash + beep cadence to sync audio to picture. But the implementation is frozen: RN 0.53 from 2018 will not compile against current Xcode, so no bug fixes, no iOS-version compatibility updates, and no App Store resubmissions are possible. Left alone, the listing will eventually be removed from the store as it falls below Apple's minimum SDK requirements. The cost of the status quo is losing distribution of a tool people already use.

## The Solution

A Flutter rebuild that is visually and behaviorally indistinguishable from today's app — same landscape layout, same swipe-to-increment / tap-to-edit gestures, same horizontal-swipe-to-mark, same red→white→green color sequence, same beep cadence, same auto-sized text filling each box. No new features. Built against the latest stable Flutter and iOS 17+, submitted as an update against the existing App Store record.

## What Makes This Approach Right

- **Parity-only scope.** No redesign, no feature additions — every hour spent on novelty is an hour not spent shipping. The existing UX is the spec.
- **Spike-gated implementation.** Three small throwaway apps validate the only three things that can derail the rebuild (nested gesture arena, audio sync precision, auto-sized text) *before* committing to milestones. Spike S2 (audio cadence) is an explicit go/no-go gate — if the audio stack can't hold sync, we change stacks before writing M1, not after.
- **Flutter over native or another RN.** Flutter is actively maintained, ships a small UI like this in days, and gives Android "for free" as upside (not as a gating commitment).

## Who This Serves

- **Primary:** the small audience of editors, AC's, and indie filmmakers already using Nobu Slate on iOS. Success for them is "the app keeps working on my current iPad and the beep stays tight."
- **Secondary (the rebuilder):** Matt, as maintainer. Success is a codebase that builds on a current Mac with a current Xcode in 2027 and beyond.

## Success Criteria

1. **Builds & submits.** App passes App Store review against the existing bundle id and ships as an update.
2. **Audio/video sync holds.** Mean offset between the on-screen flash and the corresponding beep stays within ±20ms (under one frame at 30fps) across 20 consecutive marks, including the first mark after cold start. This is the single non-functional requirement that defines whether the rebuild is acceptable.
3. **Visual parity.** Side-by-side screenshots vs. the RN app show no perceptible layout, text-sizing, or color differences.
4. **Time to ship.** 3–4 working days of implementation after the three spikes complete.

## Scope

**In v1:**
- Landscape-locked slate UI with Scene, Take, Audio File, Audio Channel L/R, Title, and live Date/Time.
- Tap-to-edit, vertical-swipe-to-increment/decrement (with A–Z letter handling and digit-width padding), horizontal-swipe-anywhere mark gesture.
- Mark action: red flash + `beep.wav` at t=0, white at t=500ms, green flash + `beep_final.wav` at t=1000ms, white + re-enable at t=1500ms.
- Local persistence of all six editable fields via `shared_preferences`.
- iOS 13+ deployment target, latest stable Flutter, reused bundle id.
- Thin smoke test only.

**Explicitly out:**
- New features (theme picker, multiple slates, cloud sync).
- Android release (the Flutter port builds for Android incidentally, but shipping it is not a v1 gate).
- Tests at parity with the original Jest + Detox suites.

## Vision

If the rebuild ships and holds sync, Nobu Slate returns to a state where small, low-risk improvements become possible again — a theme picker, multi-slate support, or an Android release — but only as separate, post-parity decisions. The point of this work is not to grow the product; it is to keep it alive on the platform editors already use, and to leave the codebase in a shape where the next change is cheap.

## Technical Notes (for downstream PRD readers)

Full technical plan, RN→Flutter mapping table, package choices (`just_audio`, `shared_preferences`, `FittedBox`/`auto_size_text`, `sentry_flutter`), spike methodology, and milestone breakdown live in `PRD.md`. The three open risks driving the spikes are: nested gesture arena (S1), audio cadence precision (S2 — go/no-go), and auto-sized text layout (S3).
