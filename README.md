# App launch readiness checklist

The 27 checks a senior reviewer runs before any App Store or Google Play submission, with a five-minute way to verify each one. Current as of October 2026.

By Robin Bhattacharyya: 20+ years building app and web architecture, Flutter, Firebase and AWS, with apps shipped on both stores.

## Who it is for

Founders and small teams shipping a mobile or web app that was built with an AI builder (Lovable, Bolt, Cursor, v0 and similar) or with Flutter, and who want to know what a store reviewer, or an attacker, will find before they do. You do not need to be a developer to read the checks. You do need someone who can run the commands.

## What is in here

| File | What it is |
|------|------------|
| [CHECKLIST.md](CHECKLIST.md) | The 27 checks: Apple review (15), Google Play (6), security and operations (6). Each one has what to check, how to verify it in under five minutes, what it prevents, and the guideline or policy to cite. |
| [SAMPLE-AUDIT.md](SAMPLE-AUDIT.md) | A **fictional** Production Readiness Audit of an invented Supabase and Next.js app, showing the report format: severity table, evidence per finding, fixes and a keep, harden or rebuild verdict. |
| [scripts/check-secrets.sh](scripts/check-secrets.sh) | A small bash script that scans a folder for the secret patterns in check 22 and prints file and line. Self-test: `scripts/test-check-secrets.sh`. |

## How to use it

1. Open [CHECKLIST.md](CHECKLIST.md) and work through it in order against the build you plan to submit, not the one on your laptop from last month.
2. For each check, run the verify step and mark it pass, fail or n/a in the scoring table at the end.
3. Run the secret scan on your repo and on your unpacked release build:
   ```bash
   scripts/check-secrets.sh path/to/your/repo
   scripts/check-secrets.sh --binary path/to/unpacked/build
   ```
   It exits 0 when clean, 1 when it finds matches, 2 on bad usage. It prints only the first characters of each match, never the full value.
4. Fix the three items the scoring section tells you to fix first. Security failures come before store failures.
5. Start the Google Play closed test (check 17) on day one if you have a personal developer account. It takes 14 days and nothing speeds it up.

Never paste real keys, user data or customer repositories into an issue or pull request here.

## Why these checks

Store review is a moving target. Recent changes that cause rejections or blocked launches today:

- **Google Play, closed testing**: new personal developer accounts need 12 testers opted in for 14 days before they can apply for production access.
- **Apple 5.1.2(i), AI consent**: since November 2025, apps must get explicit permission before sharing personal data with a third-party AI model.
- **Xcode 26**: uploads to App Store Connect have required Xcode 26 and the iOS 26 SDK since April 2026.
- **Android developer verification**: since September 2026, apps installed on certified Android devices must come from verified developers, starting in the first countries, with more in 2027.

Beyond the stores, most AI-built apps fail for the same reasons in the backend: open database rules, keys shipped to the client, no spend caps. Those are checks 22 to 27, and they matter even if the store approves you.

## Want it done for you?

- **Launch Readiness Check**: I run these checks against your app and send a scored report with the three things to fix first. [Details](#REPLACE-WITH-LAUNCH-READINESS-CHECK-LINK)
- **Store Rejection Fix**: I fix what the reviewer flagged and resubmit until it is approved. [Details](#REPLACE-WITH-STORE-REJECTION-FIX-LINK)

## Disclaimer

This is guidance from experience, not legal advice or an official statement from Apple or Google. Policies change; the checklist names the guideline behind each check so you can read the current text. If a check here disagrees with the store's current policy, the store wins. Issues and corrections are welcome.

## License

[MIT](LICENSE).
