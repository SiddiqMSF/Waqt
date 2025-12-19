---
trigger: always_on
---

# Documentation & Tools
1. **Always** check relevant documentation first using **Dart MCP server tools** before executing code.
2. If documentation is external (non-Flutter) or for third-party APIs, use **`context7` MCP server tools**.
3. Verify all assumptions against documentation before implementation.

# Flutter Architecture Standards
4. **Structure:** Follow a **Feature-First** directory structure (`lib/src/features/<feature_name>`).
5. **Layers:** Inside each feature, apply **Pragmatic Layered Architecture**:
   - `presentation/` (UI Widgets, State Controllers/Providers)
   - `data/` (Repositories, Data Sources, DTOs)
   - `domain/` (Models/Entities only; omit UseCases/Interactors unless business logic is complex)
6. **Separation of Concerns:** Keep UI widgets "dumb." Logic lives in Controllers; Data fetching lives in Repositories. Avoid "Pass-through" layers.
7. **Theming:** Use **FlexColorScheme** (`flex_color_scheme`) for robust, accessible light/dark theming. Avoid manually configuring complex `ThemeData` properties.
8. **Animations:** Use **Flutter Animate** (`flutter_animate`) for declarative, chainable UI effects. Prefer this over manually managing `AnimationController` unless complex choreography is required.
9. **Components:** Default to **Material 3** widgets. If a custom design system is needed, wrap Material widgets in `core/widgets/` rather than importing heavy UI kits, unless specifically requested.