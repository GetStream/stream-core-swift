Guidance for AI coding agents (Copilot, Cursor, Aider, Claude, etc.) working in this repository. Human readers are welcome, but this file is written for tools.

### Repository purpose

This repo hosts StreamCore, the internal Swift SDK that provides shared low-level infrastructure — WebSocket client, retry/backoff logic, logging and monitoring, dependency injection, attachment uploads, and user models — for Stream's product SDKs (StreamFeeds, StreamChat, StreamVideo). It is not designed for direct customer use and does not follow semantic versioning.

### Development guidelines

Code documentation

- Write doc comments (`///`) only for `public` declarations — types, methods, and properties that are part of the SDK's public API.
- Do not add doc comments to `internal`, `private`, or test code.
- Keep doc comments concise: a one-line summary; add parameter/return docs only when they are not obvious from the signature.
- Do not add inline comments narrating what the code or a change does; comment only non-obvious constraints or reasoning.
