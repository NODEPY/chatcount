# ChatCount

Local Telegram chat statistics. Find your most active conversations and compare each participant’s ten most-used words.

[Download for macOS, Windows and Linux](https://github.com/NODEPY/chatcount/releases/latest) · [Українська](../README.md)

## Getting started

1. Export one chat or all personal chats from Telegram Desktop as **JSON**. Media downloads are unnecessary.
2. Open **ChatCount.app** on macOS, or **ChatCount.html** in a modern browser on Windows or Linux.
3. Choose `result.json`. Select a conversation, compare participants, or export a CSV.

The browser edition also ranks all personal chats by message count. It works on macOS too. The native macOS edition currently provides word rankings and chat selection only.

## Defaults

Common-word filters for **Ukrainian, English and Russian** apply together, with a minimum of **three letters**. Interface language is independent of these filters. You can switch language, adjust length, and add your own exclusions.

## Privacy and counting

No network requests, analytics, sign-in or external libraries. Chat data stays in memory until the app or tab is closed. Downloads contain source code and fictional examples, never personal exports.

Messages include text, voice notes, stickers and media; voice notes are not transcribed. Service events, groups and Saved Messages are excluded from personal-chat rankings. Bot conversations can appear when exported as personal chats. Identifying your side requires a full account export. Different word forms are counted separately. Deleted messages and dates outside the export cannot be included.

## Platform notes

- Native macOS: macOS 13+, universal Intel / Apple Silicon binary; ad-hoc signed, not Apple-notarized.
- Windows: modern Edge or Chrome. Unzip and open the HTML file.
- Linux: modern Firefox or Chromium. If double-click opens an editor, use the browser’s **Open file** command instead.
- Web and Swift analysis tests pass. Windows/Linux desktop execution has not been manually tested.

## Development

Run `node tests/web.test.cjs` with Node.js 20+. For the native build, run `macos/build.command` on macOS with Apple Command Line Tools installed.

Report bugs with a minimal fictional example. Do not attach private Telegram exports to public issues.
