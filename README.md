# StreamCore (Swift)

**⚠️ Internal SDK — Not for public use**

This is the internal Swift SDK that powers several of Stream’s products (`StreamFeeds`, and soon `StreamChat` and `StreamVideo`). 

It provides shared low-level utilities, such as:

- A robust WebSocket client
- Retry/backoff logic
- Logging and monitoring tools
- Dependency injection and lightweight service containers
- Support for uploading attachments
- User models
- Other utils that are used in the products

## 🔒 Intended Usage

This package is **not designed for direct use by customers**. It acts as the foundation layer for other Stream SDKs and contains internal logic that is subject to change.

> If you're building an app with Stream, use [stream-chat-swift](https://github.com/GetStream/stream-chat-swift) or [stream-video-swift](https://github.com/GetStream/stream-video-swift) instead.

## ⚠️ Versioning Notice

This library does **not** follow semantic versioning. Breaking changes may be introduced at any time without warning. We reserve the right to refactor or remove functionality without deprecation periods.

## 📦 Installation

Since this SDK is internal, we do not recommend adding it directly to your project. It is primarily consumed as a dependency within other Stream SDKs via Swift Package Manager.