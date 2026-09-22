
# Localization policy / Política de localización

[English](#english) · [Español](#español)

---

# English

Localization is part of feature completion.

- Main-app copy belongs in `PowerMesh/Support/AppLanguage.swift` and resolves through `AppLanguage.text(_:)`.
- User-defined and OS-provided device names remain verbatim.
- Widget resources must exist in both `PowerMeshWidgets/en.lproj` and `PowerMeshWidgets/es.lproj`.
- System permission text must exist in both `PowerMesh/en.lproj/InfoPlist.strings` and `PowerMesh/es.lproj/InfoPlist.strings`.
- Don't hard-code parallel English/Spanish UI phrases in widget Swift.
- GitHub documentation must provide English and Spanish in the same file or an explicit paired document such as `TESTING.md` + `TESTING.es.md`.

Supported app choices remain **System**, **English**, **Español**; unsupported system languages fall back to English.

---

# Español

La localización forma parte de la definición de terminado.

- El texto de la app principal vive en `PowerMesh/Support/AppLanguage.swift` y se resuelve con `AppLanguage.text(_:)`.
- Los nombres definidos por el usuario o por el sistema se conservan literalmente.
- Los widgets deben tener recursos en `PowerMeshWidgets/en.lproj` y `PowerMeshWidgets/es.lproj`.
- Los permisos del sistema deben tener `PowerMesh/en.lproj/InfoPlist.strings` y `PowerMesh/es.lproj/InfoPlist.strings`.
- No introduzcas frases paralelas inglés/español directamente en el Swift del widget.
- La documentación de GitHub debe tener inglés y español en el mismo archivo o en un par explícito como `TESTING.md` + `TESTING.es.md`.

Las opciones siguen siendo **Sistema**, **English**, **Español**; otros idiomas del sistema usan inglés como alternativa.
