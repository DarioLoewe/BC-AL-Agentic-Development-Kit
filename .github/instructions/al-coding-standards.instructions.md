---
description: AL Coding Standards für Business-Central-Entwicklung
applyTo: "**/*.al"
---

# AL Coding Standards

Diese Instructions gelten für alle AL-Dateien in diesem Repository.

## Grundprinzipien

- Schreibe upgradefähigen, wartbaren AL-Code.
- Orientiere dich an bestehenden Patterns im Repository.
- Ändere nur Dateien, die für die Aufgabe notwendig sind.
- Vermeide große Refactorings ohne explizite Anforderung.
- Nutze Events, Interfaces und Erweiterungspunkte, bevor invasive Änderungen vorgeschlagen werden.
- Businesslogik soll nicht unnötig in Pages liegen.
- Sichtbare Texte müssen als Labels definiert werden.
- Code muss verständlich, klein und nachvollziehbar bleiben.

## Standard-BC-Objekte zuerst prüfen

**Vor jeder neuen Tabelle gilt:**
1. AL Symbole herunterladen (`al_downloadsymbols`), damit Base Application bekannt ist.
2. Prüfen ob ein Standard-BC-Äquivalent existiert (Employee, Contact, Resource, …).
3. Wenn Standard-Äquivalent vorhanden → `tableextension` erstellen, keine neue Tabelle.
4. Eigene Tabelle nur erstellen, wenn kein Standard-Objekt die fachlichen Anforderungen auch mit Extension erfüllen kann.

Diese Prüfung ist **kein optionaler Schritt** — sie verhindert redundante Datenmodelle und unsupported Duplikate.

## Objektstruktur

Bevorzugt gilt:

- ein AL-Objekt pro Datei
- Dateiname passend zum Objekt
- sprechende Objekt- und Variablennamen
- keine kryptischen Abkürzungen
- bestehende Naming-Konventionen im Repository übernehmen

Beispiele:

```al
tableextension 50100 "Customer Ext." extends Customer
pageextension 50101 "Customer Card Ext." extends "Customer Card"
codeunit 50102 "Sales Validation Mgt."
```

## Tabellen und Tabellenfelder

Bei neuen Tabellenfeldern beachten:

- sinnvollen Datentyp wählen
- Caption setzen
- DataClassification setzen
- vorhandene Fieldgroups prüfen
- Auswirkungen auf Pages, Reports, APIs und Berechtigungen prüfen
- bei FlowFields CalcFormula sauber definieren
- bei Option-Feldern nach Möglichkeit Enums bevorzugen

Beispiel:

```al
field(50100; "External Reference"; Code[50])
{
    Caption = 'External Reference';
    DataClassification = CustomerContent;
}
```

## Pages und Page Extensions

Bei Pages beachten:

- `ApplicationArea` setzen
- sichtbare Texte als Labels oder Captions
- keine komplexe Businesslogik in Page-Triggern
- Validierung möglichst in Tabellen, Codeunits oder Events auslagern
- bestehende Gruppenstruktur beachten
- Felder nur dort ergänzen, wo sie fachlich sinnvoll sind

Beispiel:

```al
addlast(General)
{
    field("External Reference"; Rec."External Reference")
    {
        ApplicationArea = All;
        ToolTip = 'Specifies the external reference for this record.';
    }
}
```

## Codeunits

Codeunits sollen fachliche Logik bündeln.

Beachte:

- kleine, fokussierte Prozeduren
- sprechende Prozedurnamen
- keine unnötigen globalen Variablen
- keine Seiteneffekte ohne Dokumentation
- keine unnötigen `COMMIT`s
- Fehlertexte als Labels

Beispiel:

```al
local procedure ValidateExternalReference(ExternalReference: Code[50])
var
    EmptyReferenceErr: Label 'External Reference must not be empty.';
begin
    if ExternalReference = '' then
        Error(EmptyReferenceErr);
end;
```

## Events und Subscriber

Bevorzugt vorhandene Events nutzen.

Bei Event Subscribern beachten:

- Subscriber klein halten
- keine unnötige Logik im Subscriber selbst
- Logik bei Bedarf in separate Codeunit auslagern
- `SkipOnMissingLicense` und `SkipOnMissingPermission` bewusst setzen
- keine unnötigen Datenbankänderungen in hochfrequenten Events

Beispiel:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
local procedure OnBeforePostSalesDoc(var SalesHeader: Record "Sales Header")
begin
    // Implementation
end;
```

## Fehlerbehandlung

- Fehlertexte als Labels definieren.
- Verständliche fachliche Fehlermeldungen schreiben.
- Keine technischen Details unnötig an Anwender ausgeben.
- `Get()` nur nutzen, wenn ein Fehler bei fehlendem Datensatz gewollt ist.
- Sonst `if not Get(...) then` verwenden.

Beispiel:

```al
if not Customer.Get(CustomerNo) then
    Error(CustomerNotFoundErr, CustomerNo);
```

## Performance

Bei großen Tabellen beachten:

- passende Keys nutzen
- Filter vor Schleifen setzen
- `FindSet()` bewusst verwenden
- keine unnötigen `Modify()`-Aufrufe
- keine teuren Berechnungen in Page-Triggern
- FlowFields nur berechnen, wenn nötig
- `SetLoadFields()` prüfen, wenn nur wenige Felder benötigt werden

Beispiel:

```al
SalesLine.SetRange("Document Type", SalesHeader."Document Type");
SalesLine.SetRange("Document No.", SalesHeader."No.");

if SalesLine.FindSet() then
    repeat
        // Logic
    until SalesLine.Next() = 0;
```

## Labels und sichtbare Texte

Alle sichtbaren Texte müssen als Labels oder Captions gepflegt werden.

Nicht verwenden:

```al
Error('Customer is blocked.');
```

Besser:

```al
CustomerBlockedErr: Label 'Customer %1 is blocked.';

Error(CustomerBlockedErr, Customer."No.");
```

## Berechtigungen

Bei neuen Objekten oder Datenzugriffen prüfen:

- PermissionSet notwendig?
- vorhandene PermissionSets erweitern?
- indirekte Berechtigungen notwendig?
- Zugriff für Zielrollen fachlich korrekt?

Keine Berechtigungen ungeprüft erweitern.

## Tests

Wenn möglich, Änderungen testbar gestalten.

Beachte:

- Businesslogik in Codeunits auslagern
- Abhängigkeiten gering halten
- klare Eingabe-/Ausgabe-Erwartungen schaffen
- Testdaten beschreiben
- Randfälle dokumentieren

## Nicht erwünscht

Vermeide:

- direkte Änderungen auf `main`
- produktive Veröffentlichungen
- Secrets im Code
- hartcodierte Zugangsdaten
- unnötige `COMMIT`s
- große Refactorings ohne Auftrag
- unklare Abkürzungen
- Businesslogik in Pages
- nicht dokumentierte Annahmen
- ungeprüfte Datenmigrationen
