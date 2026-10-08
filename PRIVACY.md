# Privacy

Bar To Do is a local web wrapper for Microsoft's official To Do website.

- It loads `https://to-do.office.com/tasks/` using Apple's WebKit.
- Microsoft and its sign-in providers receive the web requests needed to operate the site. Microsoft's privacy statement and your organization's policies govern those services.
- The wrapper does not read passwords or tokens from the page, export tasks, inject JavaScript, or implement a JavaScript-to-native bridge.
- It includes no separate analytics, telemetry service, server, or API integration operated by this project's author.
- The persistent WebKit website data store keeps cookies and other site data on the Mac. The pin preference and menu bar position are also stored locally.
- The app's web session is separate from Safari, Edge, and the native Microsoft To Do app. Sign out through Microsoft's account menu in the panel when needed. Quitting or deleting the app alone does not guarantee that WebKit website data has been removed.
- The source repository and downloadable app do not include a user's web session, cookies, account credentials, or task data.

The app can display external pages reached through the website and sign-in popups. It permits HTTPS navigation and does not bypass certificate errors. The footer displays the current page's hostname.
