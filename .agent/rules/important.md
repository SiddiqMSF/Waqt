---
trigger: always_on
---

# Documentation & Tools
1. **Always** check relevant documentation first using **Dart MCP server tools** before executing code.
2. If documentation is external (non-Flutter) or for third-party APIs, use **`context7` MCP server tools**.
3. Verify all assumptions against documentation before implementation.

# Flutter Architecture Standards
4. **Structure:** Follow a **Feature-First** directory structure (`lib/features/<feature_name>`).
5. **Layers:** Inside each feature, strictly enforce **Clean Architecture** layers:
   - `presentation/` (UI Widgets, State Controllers)
   - `domain/` (Business Logic, Entities)
   - `data/` (Repositories, API/DB calls, Models)
6. **Separation of Concerns:** Keep UI widgets "dumb." Never place HTTP calls or complex business logic directly inside Widgets.
7. **Theming:** Use **FlexColorScheme** (`flex_color_scheme`) for robust, accessible light/dark theming. Avoid manually configuring complex `ThemeData` properties.
8. **Animations:** Use **Flutter Animate** (`flutter_animate`) for declarative, chainable UI effects. Prefer this over manually managing `AnimationController` unless complex choreography is required.
9. **Components:** Default to **Material 3** widgets. If a custom design system is needed, wrap Material widgets in `core/widgets/` rather than importing heavy UI kits, unless specifically requested.