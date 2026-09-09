# Localization policy / Política de localización

[English](#english) · [Español](#español)

---

# English

## Project rule

PowerMesh is a multilingual product. Localization is not an optional cleanup step: new features must preserve language support as part of their definition of done.

## Supported app languages

The app currently supports:

- **System** — follows the device language when that language is supported.
- **English**.
- **Español**.

When System is selected and the device language is not currently supported, PowerMesh falls back to English.

The preference is persisted with `@AppStorage` under `AppLanguage.storageKey`.

## Where strings belong

All user-facing copy must be centralized in:

`PowerMesh/Support/AppLanguage.swift`

Use `AppLanguage.text(_:)` through the SwiftUI environment instead of hard-coding translated strings inside views, stores, or services.

Acceptable non-localized values include product names such as `PowerMesh`, `iPhone`, `iPad`, `Mac`, and `Apple Watch`, technical identifiers, and data received from the user or operating system that should be displayed verbatim.

## Runtime behavior

`PowerMeshApp` injects:

- `AppLanguage` through `EnvironmentValues.appLanguage`.
- A matching `Locale` through SwiftUI's `locale` environment value.

This means changing the language preference updates PowerMesh copy and locale-aware SwiftUI formatting without requiring a relaunch.

## Errors and dynamic content

Services should not permanently convert errors into a specific UI language. Keep technical or raw error details in state, then add localized explanatory text in the view.

User-defined device names must never be translated.

## Adding a new language

1. Add a new `AppLanguage` case.
2. Add the corresponding locale and resolution behavior.
3. Add a complete translation table for every `AppText` key.
4. Add the language to the Settings picker through `AppLanguage.allCases`.
5. Verify Dashboard, Settings, battery cards, macOS menu bar, accessibility labels, error states, and empty states.
6. Update every GitHub document in both English and Spanish to mention the newly supported language where relevant.
7. When an Xcode project and automated tests are present, add a completeness test ensuring every `AppText` key has a translation.

## GitHub documentation rule

All project-owned documentation in the repository must contain both **English and Spanish** versions. This includes, when created:

- `README.md`
- files under `docs/`
- contribution guides
- setup guides
- architecture notes
- release/process documentation

Code symbols, commit messages, branch names, and technical identifiers may remain in English for consistency.

## Future migration to String Catalogs

The current source-only repository uses a centralized Swift localization table so the behavior is testable and understandable even before the final `.xcodeproj` is committed.

Once the complete Xcode project exists, PowerMesh may migrate the translation storage to Apple's String Catalog (`.xcstrings`) while preserving the same three language modes and centralized no-hard-coded-UI-string policy.

---

# Español

## Regla del proyecto

PowerMesh es un producto multilingüe. La localización no es una tarea opcional para después: las nuevas funciones deben conservar el soporte de idiomas como parte de su definición de terminado.

## Idiomas admitidos en la app

La aplicación admite actualmente:

- **Sistema** — sigue el idioma del dispositivo cuando ese idioma está soportado.
- **English**.
- **Español**.

Cuando se selecciona Sistema y el idioma del dispositivo todavía no está soportado, PowerMesh utiliza inglés como alternativa.

La preferencia se conserva con `@AppStorage` mediante `AppLanguage.storageKey`.

## Dónde deben vivir los textos

Todo el contenido visible para el usuario debe centralizarse en:

`PowerMesh/Support/AppLanguage.swift`

Usa `AppLanguage.text(_:)` mediante el entorno de SwiftUI en lugar de escribir traducciones directamente dentro de vistas, stores o servicios.

Los valores que pueden permanecer sin traducir incluyen nombres de producto como `PowerMesh`, `iPhone`, `iPad`, `Mac` y `Apple Watch`, identificadores técnicos y datos proporcionados por el usuario o por el sistema operativo que deban mostrarse literalmente.

## Comportamiento en ejecución

`PowerMeshApp` inyecta:

- `AppLanguage` mediante `EnvironmentValues.appLanguage`.
- Un `Locale` correspondiente mediante el valor de entorno `locale` de SwiftUI.

Esto permite que cambiar la preferencia actualice los textos de PowerMesh y el formato dependiente del locale sin requerir reiniciar la aplicación.

## Errores y contenido dinámico

Los servicios no deben convertir de forma permanente los errores a un idioma específico de interfaz. Conserva el detalle técnico o sin procesar en el estado y añade la explicación localizada en la vista.

Los nombres de dispositivos definidos por el usuario nunca deben traducirse.

## Añadir un idioma nuevo

1. Añade un nuevo caso a `AppLanguage`.
2. Añade su locale y comportamiento de resolución.
3. Añade una tabla de traducción completa para cada clave de `AppText`.
4. Añade el idioma al selector de Configuración mediante `AppLanguage.allCases`.
5. Verifica Dashboard, Configuración, tarjetas de batería, menú de macOS, etiquetas de accesibilidad, errores y estados vacíos.
6. Actualiza toda la documentación de GitHub en inglés y español para mencionar el nuevo idioma cuando corresponda.
7. Cuando exista el proyecto Xcode y pruebas automatizadas, añade una prueba de integridad que garantice una traducción para cada clave de `AppText`.

## Regla para la documentación de GitHub

Toda la documentación propia del proyecto dentro del repositorio debe contener versiones en **inglés y español**. Esto incluye, cuando existan:

- `README.md`
- archivos dentro de `docs/`
- guías de contribución
- guías de instalación
- notas de arquitectura
- documentación de versiones y procesos

Los símbolos de código, mensajes de commit, nombres de ramas e identificadores técnicos pueden permanecer en inglés por consistencia.

## Migración futura a String Catalogs

El repositorio actual, todavía basado únicamente en código fuente, usa una tabla centralizada de localización en Swift para que el comportamiento sea comprensible y verificable incluso antes de incluir el `.xcodeproj` definitivo.

Cuando exista el proyecto Xcode completo, PowerMesh podrá migrar el almacenamiento de traducciones a String Catalog de Apple (`.xcstrings`) manteniendo los mismos tres modos de idioma y la regla de no introducir textos de interfaz codificados directamente.
