# Onboarding — Nobu Slate (Flutter)

Everything you need to do on a fresh macOS machine to build, run, and submit this app. Designed around **asdf** so the Flutter, Dart, Ruby, and CocoaPods versions are reproducible.

> Tested on: macOS 15 (Darwin 25.x), Apple Silicon. Should work on Intel Macs with no changes.

---

## 1. Prerequisites (one-time, system-level)

These can't be managed by asdf and must come from Apple or Homebrew.

### 1.1 Xcode (required for iOS builds)

```bash
# Install from the App Store, then:
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
xcodebuild -runFirstLaunch
```

Verify:

```bash
xcode-select -p          # → /Applications/Xcode.app/Contents/Developer
xcodebuild -version      # → Xcode 16.x or newer
```

### 1.2 iOS Simulator runtime

```bash
xcodebuild -downloadPlatform iOS
```

(Or open Xcode → Settings → Components and download the latest iOS simulator runtime.)

### 1.3 Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 1.4 asdf (already installed on this machine, but for a fresh box)

```bash
brew install asdf
# Then add to ~/.zshrc:
#   . "$(brew --prefix asdf)/libexec/asdf.sh"
```

Verify:

```bash
asdf --version           # → 0.16.x or newer
```

---

## 2. Project toolchain (asdf-managed)

From inside this repo:

### 2.1 Flutter + Dart

```bash
asdf plugin add flutter https://github.com/oae/asdf-flutter.git
asdf install flutter latest
# The version that installed will appear in `.tool-versions` after the next step.
```

### 2.2 Ruby (for CocoaPods)

```bash
asdf plugin add ruby
asdf install ruby 3.2.2       # Match the version in .tool-versions
```

### 2.3 Pin versions for this project

The repo's `.tool-versions` already declares:

```
flutter <version>
ruby 3.2.2
```

After `asdf install` for each, `cd` into the repo and confirm:

```bash
asdf current
# flutter   <version>   .tool-versions
# ruby      3.2.2        .tool-versions
```

### 2.4 CocoaPods (Ruby gem, version pinned via Gemfile)

There is no clean asdf plugin for CocoaPods, so we use the canonical Ruby pattern: a `Gemfile` pins the version, asdf-managed Ruby provides the runtime.

```bash
# From the repo root, with asdf-ruby active:
gem install bundler
bundle install
```

This installs CocoaPods at the exact version pinned in `Gemfile.lock`. From then on, **always** invoke pods via `bundle exec`:

```bash
bundle exec pod install
bundle exec pod repo update
```

(Flutter itself shells out to `pod`. To make Flutter use the bundled version, ensure `bundle exec` is in the path or set `flutter config --no-enable-ios` to skip — easier: trust that as long as `gem install cocoapods` was run in this Ruby, the right binary is first on PATH.)

Verify:

```bash
which pod                # → ~/.asdf/installs/ruby/3.2.2/bin/pod (NOT /usr/local/bin/pod or /opt/homebrew/bin/pod)
pod --version            # → matches Gemfile.lock
```

If `which pod` shows a non-asdf path, you have a stale Homebrew or system CocoaPods shadowing the asdf one. Fix:

```bash
brew uninstall cocoapods 2>/dev/null
sudo gem uninstall cocoapods -aIx 2>/dev/null  # only for the system Ruby
asdf reshim ruby
```

---

## 3. Verify everything

```bash
flutter doctor -v
```

Expected: green checks for Flutter, Dart, Xcode, CocoaPods, iOS toolchain. The "Android toolchain" and "Chrome" lines can stay red — we're shipping iOS only.

---

## 4. First build

```bash
# Open an iOS simulator
open -a Simulator

# Run the app
flutter run -d iphone     # picks the open simulator
```

For a physical device build (for TestFlight):

```bash
flutter build ipa --release
# Output at: build/ios/ipa/nobu_slate.ipa
```

Then upload via Xcode → Window → Organizer, or `xcrun altool --upload-app`.

---

## 5. Troubleshooting

| Symptom | Fix |
|---|---|
| `pod: command not found` after `gem install` | Run `asdf reshim ruby` |
| `flutter doctor` says CocoaPods missing despite being installed | `which pod` → if it points outside asdf, see §2.4 cleanup |
| `flutter` command not found in a new terminal | Confirm `.zshrc` sources asdf, and `cd` into the repo so `.tool-versions` takes effect |
| Xcode build fails with "no provisioning profile" | Open `ios/Runner.xcworkspace` in Xcode, set Signing & Capabilities → Team |
| Pod install fails with `ffi` errors on Apple Silicon | `arch -arm64 bundle exec pod install` |
| `flutter run` hangs on "Running Xcode build" | First build on a clean machine can take 10+ min — let it finish; subsequent builds are fast |

---

## 6. Why this setup

- **asdf for Flutter** so the SDK version is pinned per-project, the same way you already pin Ruby/Node/Python on this machine.
- **Bundler for CocoaPods** instead of `gem install cocoapods` globally, so the pod version is reproducible across machines and CI without conflicting with system Ruby.
- **No `sudo gem`, no Homebrew CocoaPods.** Both create version-skew pain that's easy to avoid by living entirely inside asdf-managed Ruby.

---

## 7. Quick reference

```bash
# Daily dev loop
flutter run

# Update Flutter SDK
asdf install flutter latest
asdf local flutter <new-version>    # updates .tool-versions

# Update pods after editing ios/Podfile
cd ios && bundle exec pod install && cd ..

# Clean rebuild
flutter clean && flutter pub get && cd ios && bundle exec pod install && cd ..
```
