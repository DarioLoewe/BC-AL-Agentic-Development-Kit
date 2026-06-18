---
description: Analysiert ein Azure DevOps Work Item und bereitet es für die AL-Entwicklung auf.
---

Analysiere das folgende Azure DevOps Work Item für die Business-Central-AL-Entwicklung.

Work Item:
${input:Work-Item-Inhalt (Titel, Beschreibung, Akzeptanzkriterien)}

Erzeuge:

1. **Zusammenfassung** — Was wird fachlich verlangt?
2. **Annahmen** — Welche Informationen werden als bekannt vorausgesetzt?
3. **Fehlende Informationen** — Was muss der Entwickler noch klären?
4. **Akzeptanzkriterien** — Abgeleitet aus dem Work Item, messbar formuliert
5. **Betroffene BC-Bereiche** — z. B. Verkauf, Lager, Buchhaltung, Berechtigungen, Posten
6. **Empfohlene nächste Schritte** — Plan starten / Rückfrage stellen / Blocker dokumentieren

Wenn das Work Item die Bereiche Buchungslogik, Preise, Lager, Posten, Berechtigungen,
Datenmigration oder Schnittstellen betrifft, weise explizit auf das erhöhte Risiko hin und
empfehle vollständige Akzeptanzkriterien vor Implementierungsbeginn.
