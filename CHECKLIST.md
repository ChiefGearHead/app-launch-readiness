# Launch readiness checklist

27 checks to run before submitting to the App Store or Google Play. Current as of October 2026.

Each check has four parts:

- **Check**: what must be true.
- **Verify**: the fastest way to confirm it, under five minutes. Commands assume a Flutter project layout (`ios/Runner`, `android/app`); the idea is the same in native or React Native projects.
- **Prevents**: the rejection or incident you avoid.
- **Reference**: the guideline or policy to cite. Store policies change. The section numbers and dates below were correct in October 2026; look up the named guideline or policy on developer.apple.com or in the Google Play Console Help before relying on a date.

Score each item **pass**, **fail** or **n/a** and finish with the scoring section at the bottom.

**Contents:** [Apple review](#apple-review) (1 to 15) · [Google Play](#google-play) (16 to 21) · [Security and operations](#security-and-operations) (22 to 27) · [Scoring](#scoring)

---

## Apple review

### 1. Privacy policy URL works and names every third party

- **Check**: the privacy policy URL entered in App Store Connect and shown in the app returns 200 and names every third party that receives user data (analytics, crash reporting, AI providers, payments, ads).
- **Verify**:
  ```bash
  curl -s -o /dev/null -w "%{http_code}\n" -L https://example.com/privacy
  ```
  Then list your SDKs (`pubspec.yaml`, check 5) and confirm each one appears in the policy text.
- **Prevents**: rejection for a missing, broken or incomplete privacy policy; a policy that contradicts your App Privacy answers.
- **Reference**: App Review Guideline 5.1.1(i); App Store Connect, App Information > Privacy Policy URL.

### 2. Support URL works

- **Check**: the support URL returns 200 and leads to a real way to contact you (form, email, help page).
- **Verify**:
  ```bash
  curl -s -o /dev/null -w "%{http_code}\n" -L https://example.com/support
  ```
  Open it on a phone; a page that only works on desktop still counts as a fail for a mobile reviewer.
- **Prevents**: rejection for unreachable developer contact details, and unanswerable user complaints after launch.
- **Reference**: App Review Guideline 1.5 (Developer Information); App Store Connect, App Information > Support URL.

### 3. In-app account deletion deletes the user and their data

- **Check**: if the app lets people create an account, they can start deletion from inside the app. It deletes the auth user and the user's data (database rows, storage files, third-party records), not just deactivates it.
- **Verify**: create a test user, add some data, delete the account from Settings, then confirm in the console that the auth user and the data are gone. Firebase: Authentication > Users, then Firestore and Storage. Supabase: Authentication > Users and the Table Editor.
- **Prevents**: one of the most common rejections for apps with sign-up; orphaned personal data that breaks your own privacy policy.
- **Reference**: App Review Guideline 5.1.1(v).

### 4. Consent before user data goes to a third-party AI model

- **Check**: before any user content is sent to a third-party AI provider, the app shows a clear consent screen naming the provider and what is sent, and there is a way to withdraw consent later (a settings toggle).
- **Verify**: fresh install, trigger the AI feature, and watch what happens first. Then check the network tab or proxy logs (Charles, mitmproxy) to confirm nothing is sent to the AI endpoint before consent. Confirm the toggle exists and that turning it off stops the calls.
- **Prevents**: rejection for sharing personal data with third-party AI without disclosure and permission, enforced since November 2025.
- **Reference**: App Review Guideline 5.1.2(i).

### 5. Privacy nutrition labels match the SDKs actually linked

- **Check**: the App Privacy answers in App Store Connect describe the data your app and its SDKs collect, including SDKs you did not write.
- **Verify**:
  ```bash
  # direct and transitive Dart packages
  grep -E "^  [a-z0-9_]+:$" pubspec.lock
  # iOS pods actually linked
  sed -n '/^PODS:/,/^DEPENDENCIES:/p' ios/Podfile.lock | grep -E "^  - " | sed 's/ (.*//'
  ```
  Compare against the labels. In Xcode, Product > Archive > Distribute, or the archive's Generate Privacy Report, shows the aggregated manifests.
- **Prevents**: rejection or later removal for inaccurate privacy labels; labels that disagree with the privacy policy.
- **Reference**: App Privacy Details (App Store Connect > App Privacy); App Review Guideline 5.1.1.

### 6. Privacy manifest present, required-reason APIs declared

- **Check**: the app has a `PrivacyInfo.xcprivacy`, declares every required-reason API it uses with an approved reason, and the third-party SDKs that require a manifest ship one.
- **Verify**:
  ```bash
  find ios -name PrivacyInfo.xcprivacy -not -path "*/Pods/*"
  find ios/Pods -name PrivacyInfo.xcprivacy 2>/dev/null | wc -l
  ```
  Upload a build to TestFlight and read the email from App Store Connect; missing declarations show up as `ITMS-91053` (undeclared API) or `ITMS-91061` (SDK without manifest).
- **Prevents**: upload warnings and rejections at processing time; surprises when an old plugin version lacks a manifest.
- **Reference**: Apple, "Privacy manifest files" and "Describing use of required reason API".

### 7. Built with the current required Xcode and SDK

- **Check**: the build you upload was made with Xcode 26 and the iOS 26 SDK, which App Store Connect has required since April 2026.
- **Verify**:
  ```bash
  xcodebuild -version
  xcrun --sdk iphoneos --show-sdk-version
  flutter doctor -v | grep -i xcode
  ```
  In CI, print both in the build log so a runner image update cannot silently downgrade you.
- **Prevents**: the upload being refused at App Store Connect with an SDK version error, often discovered the night before a launch.
- **Reference**: Apple Developer News, "Upcoming requirements" (Xcode 26 / iOS 26 SDK, April 2026).

### 8. Launches on iPad and the oldest supported iPhone

- **Check**: the app launches and the main flows work on the latest iPadOS (even if you only target iPhone, the app runs on iPad unless you opt out) and on your oldest supported iPhone, with no crash and no overflowed layouts. If multitasking is on, all four iPad orientations are declared.
- **Verify**:
  ```bash
  xcrun simctl list devices available | grep -i ipad
  flutter run -d <ipad-simulator-udid>
  ```
  Rotate the simulator and open every main screen. For Flutter, look for yellow-black overflow stripes and check `UISupportedInterfaceOrientations~ipad` in `ios/Runner/Info.plist`.
- **Prevents**: "crashed on launch" and layout-broken rejections on the reviewer's iPad; upload error `ITMS-90474` (missing orientations).
- **Reference**: App Review Guideline 2.1 (App Completeness) and 2.4.1 (iPad compatibility).

### 9. Camera, photo, location and microphone usage strings present and specific

- **Check**: every protected resource the app (or an SDK) touches has an `NS...UsageDescription` in `Info.plist` that tells the user why, in plain words specific to your app.
- **Verify**:
  ```bash
  grep -A1 -E "NS[A-Za-z]+UsageDescription" ios/Runner/Info.plist
  ```
  Each string should say what your app does with the permission, not "This app needs camera access".
- **Prevents**: rejection for vague purpose strings; upload error `ITMS-90683` (missing purpose string); a crash the moment the permission is requested.
- **Reference**: App Review Guideline 5.1.1(ii) and Apple, "Requesting access to protected resources".

### 10. Digital goods use in-app purchase, with restore and subscription terms

- **Check**: anything digital that is unlocked inside the app is sold through in-app purchase, not an external checkout. There is a Restore Purchases button. Subscription screens show price, period, auto-renewal terms and links to terms and privacy.
- **Verify**: walk through every paywall and upgrade button on a fresh install. Search the code for external payment links:
  ```bash
  grep -rniE "stripe\.com|checkout|paypal|buy.*link" lib/ | head -20
  ```
  Confirm the restore button works after reinstall with a sandbox account.
- **Prevents**: the 3.1.1 rejection that forces a product change late in the process; rejection for incomplete subscription disclosure.
- **Reference**: App Review Guideline 3.1.1 (In-App Purchase) and 3.1.2 (Subscriptions).

### 11. Sign in with Apple if a third-party social login exists

- **Check**: if the app offers Google, Facebook or another third-party login as the way to create or use an account, it also offers Sign in with Apple or an equivalent privacy-preserving login (limits data collected to name and email, lets the user hide the email, no ad tracking without consent).
- **Verify**: open the login screen and list the buttons. Then check the code for the providers:
  ```bash
  grep -rnE "GoogleSignIn|google_sign_in|FacebookAuth|flutter_facebook|sign_in_with_apple" pubspec.yaml lib/
  ```
- **Prevents**: a 4.8 rejection, which is easy to hit with Firebase Auth templates that add Google first.
- **Reference**: App Review Guideline 4.8 (Login Services).

### 12. Demo account and reviewer notes ready, login reachable without a real phone number

- **Check**: App Store Connect > App Review Information has a working demo account (not expiring, with sample data) and notes explaining non-obvious flows. No login step needs an SMS code or an email the reviewer cannot receive.
- **Verify**: log out of everything, install the TestFlight build on a clean device, and sign in using only what you wrote in the review notes. If you use phone auth, set up a Firebase test phone number and put it in the notes.
- **Prevents**: "we could not sign in" rejections (guideline 2.1), the single most common cause of a one-day delay.
- **Reference**: App Review Guideline 2.1 (App Completeness) and App Review Information in App Store Connect.

### 13. Minimum functionality: not a wrapper, not a template

- **Check**: the app offers lasting, app-like value beyond a website in a frame or an unmodified template, and has its own identity (icon, name, content).
- **Verify**: read the app as a reviewer would, five minutes with no help. Search for signs of a shell:
  ```bash
  grep -nE "webview" pubspec.yaml
  grep -rn "flutter_application\|My App\|Hello World" android/app/src/main ios/Runner/Info.plist
  ```
  If the core is one `WebView`, say what native capability justifies the app (push, offline, device APIs) in the review notes.
- **Prevents**: 4.2 minimum functionality and 4.3 spam rejections, which are hard to appeal once issued.
- **Reference**: App Review Guideline 4.2 (Minimum Functionality) and 4.3 (Spam).

### 14. Export compliance answered, encryption declared

- **Check**: the encryption declaration is set in `Info.plist` so the export compliance question does not block each upload, and the answer is correct for your app (standard HTTPS only is usually exempt).
- **Verify**:
  ```bash
  grep -A1 ITSAppUsesNonExemptEncryption ios/Runner/Info.plist
  ```
  If it is missing, App Store Connect asks on every build.
- **Prevents**: builds stuck at "Missing Compliance"; an incorrect declaration, which is a legal problem rather than a review one.
- **Reference**: Apple, "Complying with Encryption Export Regulations"; App Store Connect > App Information.

### 15. Age rating matches content; health data follows HealthKit rules

- **Check**: the age rating questionnaire in App Store Connect reflects the real content (user-generated content, chat, mature themes, AI-generated content, in-app controls). If the app uses health data or HealthKit, it follows the health data rules.
- **Verify**: open App Store Connect > App Information > Age Rating and re-answer each question against the current build. For health data, grep for `HealthKit` and check the entitlement and usage strings:
  ```bash
  grep -rn "HealthKit\|NSHealth" ios/Runner/ pubspec.yaml
  ```
- **Prevents**: age rating corrections after approval, rejection for health data used for advertising or stored in iCloud, and mismatch with Google Play's content rating.
- **Reference**: App Review Guideline 1.2 (user-generated content), 5.1.3 (Health and Health Research); Apple age rating documentation.

---

## Google Play

### 16. Developer account exists and identity is verified

- **Check**: the Play developer account is created, its identity verification is complete, and you know whether the Android developer verification requirement applies to your distribution (enforcement began on 30 September 2026 in the first countries, with more to follow in 2027).
- **Verify**: Play Console > Home shows no verification banner; Settings > Developer account > Account details shows verified status. Read the Android developer verification page on developer.android.com and check whether your target countries are in the current enforcement list.
- **Prevents**: being unable to publish or update, and apps that install with a warning or are blocked on certified devices in enforced regions.
- **Reference**: Google Play Console Help, "Verify your developer identity"; Android developer verification requirements (developer.android.com).

### 17. Personal account: closed test with 12 testers for 14 days before production

- **Check**: if the developer account is a personal account created after November 2023, a closed test with at least 12 opted-in testers has run for 14 continuous days before you can apply for production access. Organization accounts are not subject to this.
- **Verify**: Play Console > Test and release > Testing > Closed testing: count opted-in testers and the days elapsed. The Dashboard shows a "Apply for production" checklist with the progress of this requirement. Start this on day one; it is usually the critical path.
- **Prevents**: a launch blocked for two weeks with no way to speed it up; testers dropping out and resetting the count.
- **Reference**: Google Play Console Help, "App testing requirements for new personal developer accounts".

### 18. Target API level, release-signed AAB, Play App Signing, SHA-256 registered

- **Check**: the app targets the API level Play currently requires (API 36 for new apps and updates since 31 August 2026; confirm on the Target API level page), the upload is a release-signed AAB, Play App Signing is on, and the Play signing SHA-256 is registered in Firebase and in `assetlinks.json`.
- **Verify**:
  ```bash
  bundletool dump manifest --bundle build/app/outputs/bundle/release/app-release.aab | grep targetSdkVersion
  keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab | grep -E "Owner|SHA256"
  curl -s https://example.com/.well-known/assetlinks.json
  ```
  The signer must not be an "Android Debug" certificate. Copy the app signing SHA-256 from Play Console > Test and release > App integrity > App signing into Firebase project settings and `assetlinks.json`.
- **Prevents**: upload refused for an outdated target API; Google sign-in and App Links that work in debug and break in production because the signing key changed.
- **Reference**: Google Play Console Help, "Target API level requirements"; Play App Signing documentation; Android App Links verification.

### 19. Data safety form matches actual collection and the privacy policy

- **Check**: the Data safety form lists the data your app and its SDKs collect and share, whether it is encrypted in transit, and whether users can request deletion, consistent with the privacy policy and the Apple labels.
- **Verify**: Play Console > Policy and programs > App content > Data safety. Take the SDK list from check 5 and the Android dependency list:
  ```bash
  cd android && ./gradlew app:dependencies --configuration releaseRuntimeClasspath | grep -E "firebase|google|facebook|adjust|appsflyer|sentry"
  ```
  Each analytics, crash, ads or AI SDK maps to at least one answered data type.
- **Prevents**: policy violation notices and update rejections for a form that contradicts what the app does.
- **Reference**: Google Play User Data policy; Data safety section help.

### 20. Account deletion URL submitted in Play Console

- **Check**: for apps that let people create accounts, Play Console has a web URL where users can request deletion of their account and data, and the in-app path matches check 3.
- **Verify**: Play Console > Policy and programs > App content > Data deletion. Open the URL in a private window and confirm a person can complete or start a request without installing the app.
- **Prevents**: update blocks and policy warnings for apps with accounts and no external deletion path.
- **Reference**: Google Play User Data policy, account deletion requirements.

### 21. Declared permissions are used; no broad permissions without justification

- **Check**: every permission in the merged manifest is used by a feature. No `QUERY_ALL_PACKAGES` unless the policy allows your use, and no background location without the declaration form.
- **Verify**:
  ```bash
  bundletool dump manifest --bundle build/app/outputs/bundle/release/app-release.aab | grep -E "uses-permission"
  ```
  The merged manifest includes permissions added by plugins, so check the built bundle rather than `AndroidManifest.xml` only. Remove what you do not use with `tools:node="remove"`.
- **Prevents**: rejection under the permissions policy, or a Play Console declaration form you did not know you needed, and users abandoning the install screen.
- **Reference**: Google Play "Permissions and APIs that Access Sensitive Information" policy; `QUERY_ALL_PACKAGES` and background location policies.

---

## Security and operations

### 22. No secrets in the bundle

- **Check**: the repo and the built artifacts contain no private API keys, service account files or admin credentials. Keys that are meant to be public (Firebase web key, Supabase anon key) are restricted. Public-prefixed environment variables (`NEXT_PUBLIC_`, `VITE_`, `EXPO_PUBLIC_`) never carry a secret.
- **Verify**: scan the source with the script in this repo, then the unpacked build:
  ```bash
  scripts/check-secrets.sh path/to/repo
  unzip -q app-release.apk -d /tmp/apk && scripts/check-secrets.sh --binary /tmp/apk
  ```
  The patterns searched are `sk-`, `sk-proj-`, `AIza` (a Google key; check it is restricted in Google Cloud Console > APIs and Services > Credentials), `service_account`, `private_key`, `SUPABASE_SERVICE_ROLE`, and public-prefixed variables containing words like SECRET, TOKEN or API_KEY. A match is a lead, not a verdict; read each one.
- **Prevents**: stolen keys and surprise bills, data breach through an exposed admin key, and a rotate-everything weekend after launch. Anything found in a public build must be treated as compromised and rotated.
- **Reference**: OWASP MASVS-STORAGE; CWE-798 (hard-coded credentials); Google Cloud documentation on API key restrictions.

### 23. Database rules are not in test mode

- **Check**: Firestore or Storage rules and Supabase policies are not open. A signed-in user cannot read or write another user's documents, and an anonymous user cannot read private data.
- **Verify**:
  - Firebase: Console > Firestore > Rules. Look for `allow read, write: if true` or a time-limited test-mode rule. Test with the emulator as a non-owner user.
  - Supabase, in the SQL editor:
    ```sql
    select schemaname, tablename, rowsecurity
    from pg_tables
    where schemaname = 'public' and not rowsecurity;
    ```
    Every table with user data should be absent from this list. Then query with a second user's JWT and confirm it returns nothing. The dashboard's Security Advisor lists the same findings.
- **Prevents**: the most common serious breach in AI-built and prototype-grown apps: anyone with the project URL reading or deleting every user's data.
- **Reference**: OWASP Top 10 A01 Broken Access Control and API Security Top 10 API1 (Broken Object Level Authorization); Firebase Security Rules and Supabase Row Level Security documentation.

### 24. Development and production use separate backend projects

- **Check**: debug and release builds point at different Firebase or Supabase projects. Testing never touches real users' data, and a bad script cannot wipe production.
- **Verify**:
  ```bash
  cat .firebaserc
  grep -h '"project_id"' android/app/src/*/google-services.json
  grep -rh "supabase.co" .env* lib/ 2>/dev/null | sort -u
  ```
  More than one project id or URL across build modes is a pass; one shared id is a finding.
- **Prevents**: test accounts and junk data in production, accidental deletes, and quota or cost exhaustion from development traffic.
- **Reference**: Firebase "Set up multiple environments"; Twelve-Factor App, config and dev/prod parity.

### 25. Budget alerts exist on cloud and every AI provider

- **Check**: the cloud project and each pay-per-use AI provider has a budget with alerts (and a hard limit where the provider offers one).
- **Verify**:
  - Google Cloud: Console > Billing > Budgets and alerts. Firebase projects use the same billing account.
  - AWS: Billing > Budgets.
  - AI providers: the usage limits or billing page of each provider's console (OpenAI, Anthropic, Google AI and others) shows a monthly limit and notification email.
- **Prevents**: a runaway loop, a leaked key or a viral day turning into a four-figure bill that you find out about from the invoice. Note that most cloud budgets alert but do not cap spend.
- **Reference**: Google Cloud Billing budgets documentation; AWS Budgets; each provider's usage limit documentation.

### 26. Crash reporting present and symbols uploaded

- **Check**: Crashlytics or Sentry is initialized in release builds, and symbol files are uploaded so stack traces are readable (dSYMs for iOS, mapping or debug symbols for Android and Flutter).
- **Verify**:
  ```bash
  grep -nE "firebase_crashlytics|sentry_flutter" pubspec.yaml
  grep -rn "FlutterError.onError\|runZonedGuarded\|SentryFlutter.init" lib/
  ```
  Then force a test crash in a release build and confirm it appears in the console with a readable stack trace within a few minutes.
- **Prevents**: launching blind, so the first sign of a crash loop is a one-star review; unreadable stack traces after obfuscation; guideline 2.1 crash rejections you cannot reproduce.
- **Reference**: Firebase Crashlytics and Sentry documentation; Flutter "Obfuscate Dart code" (symbols must be kept); Play Console Android vitals.

### 27. Minors and personal or health data

- **Check**: if children could use the app and it holds personal or health data, there is an age gate or the app is designed for it, and store age policies and COPPA (and GDPR Article 8 for the EU) are accounted for.
- **Verify**: ask three questions. Is the app appealing to children? Is there any age check at sign-up? Does the data model hold health, location, photos or chat for those users? Cross-check the age rating (check 15) and the Play target audience and content questionnaire (Play Console > App content > Target audience and content).
- **Prevents**: removal for violating the kids or families policies, regulatory exposure, and rebuilding the data layer after launch.
- **Reference**: COPPA (US 16 CFR Part 312); GDPR Article 8; App Review Guidelines 1.3 and 5.1.4; Google Play Families policy.

---

## Scoring

For each check, write **pass**, **fail** or **n/a** with a date.

| # | Check | Result | Date | Note |
|---|-------|--------|------|------|
| 1 | Privacy policy URL | | | |
| 2 | Support URL | | | |
| 3 | Account deletion in app | | | |
| 4 | AI consent | | | |
| 5 | Privacy labels match SDKs | | | |
| 6 | Privacy manifest | | | |
| 7 | Xcode 26 / iOS 26 SDK | | | |
| 8 | iPad and oldest iPhone | | | |
| 9 | Usage strings | | | |
| 10 | In-app purchase, restore, terms | | | |
| 11 | Sign in with Apple | | | |
| 12 | Demo account and notes | | | |
| 13 | Minimum functionality | | | |
| 14 | Export compliance | | | |
| 15 | Age rating, health data | | | |
| 16 | Play developer verification | | | |
| 17 | 12 testers for 14 days | | | |
| 18 | Target API, AAB, signing | | | |
| 19 | Data safety form | | | |
| 20 | Play account deletion URL | | | |
| 21 | Permissions | | | |
| 22 | No secrets in bundle | | | |
| 23 | Database rules | | | |
| 24 | Separate dev and prod | | | |
| 25 | Budget alerts | | | |
| 26 | Crash reporting and symbols | | | |
| 27 | Minors | | | |

**Score:** ___ pass, ___ fail, ___ n/a out of 27.

**Fix first (pick three):** any security fail (22, 23, 24) beats any store fail, because it can hurt users before a reviewer ever sees the app. Then the fail that is slowest to resolve (17 takes 14 days; 16 and 7 can block upload outright). Then the fail most likely to be rejected on first review (3, 4, 12).

1. ______________________
2. ______________________
3. ______________________

Everything else goes on the list in order of the table above.
