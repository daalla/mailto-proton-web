# Mailto Proton Web

A lightweight macOS agent that handles system-wide `mailto:` links and opens the [Proton Mail](https://mail.proton.me) web composer in Google Chrome, without an intermediate window or Dock icon. It does not configure email accounts or modify Apple Mail.

## Behavior

- Click a `mailto:` link in any application to open Proton in Chrome. If Chrome is unavailable, the default browser is used.
- The agent quits after handing off the URL; no background startup item is needed.
- Hold **Option (⌥)** while clicking a link to show recipients, Cc, Bcc, subject, and body instead. The window provides **Copy**, **Copy all**, **Open in Proton**, and **Close** actions.
- Launch the app without a URL to open preferences: **Open directly in Proton** (enabled by default) and **Restore Mail as default app**.
- Multiple recipients, UTF-8 text, and multiline bodies are supported.

## Requirements

- macOS 13 or later (tested on macOS 26 Tahoe).
- Xcode Command Line Tools (`swiftc`) to build.

## Build and install

```bash
cd ~/Developer/mailto-proton-web
./build.sh install
```

Installs `~/Applications/Mailto Proton Web.app`, signed ad hoc (not notarized).

## Set the default handler

```bash
APP="$HOME/Applications/Mailto Proton Web.app/Contents/MacOS/MailtoProtonWeb"
"$APP" --set-default
"$APP" --query-default
```

Accept a macOS confirmation dialog if prompted. The query should print `com.daalla.mailtoprotonweb`. This changes only the link handler, not email accounts.

## Command-line tools

```bash
APP="$HOME/Applications/Mailto Proton Web.app/Contents/MacOS/MailtoProtonWeb"
"$APP" --help
"$APP" --print-proton 'mailto:ana@example.com?subject=Hello'
"$APP" --inspect 'mailto:ana@example.com,bob@example.com?cc=c@example.com&bcc=d@example.com&subject=Test&body=Hello%0ASecond%20line'
```

## Restore Apple Mail

Open preferences and select **Restore Mail as default app**, or run:

```bash
"$HOME/Applications/Mailto Proton Web.app/Contents/MacOS/MailtoProtonWeb" --restore-mail
```

Once Mail is restored, the app can be removed from `~/Applications`.

## Proton URL format

Uses Proton web's `MAILTO_PROTOCOL_HANDLER_PATH` from `applications/mail/src/app/constants.ts`:

```text
https://mail.proton.me/inbox/#mailto=%s
```

`%s` is the complete `mailto:` URL encoded with JavaScript-compatible `encodeURIComponent` semantics. Recipients, subject, and body are passed to Proton; this app never sends mail.

Bundle identifier: `com.daalla.mailtoprotonweb`. Preference key: `openDirectlyInProton` in the app's UserDefaults domain; an unset key means enabled.
