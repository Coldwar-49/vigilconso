---
status: partial
phase: 01-recherche-filtres
source: [01-VERIFICATION.md]
started: 2026-06-18T00:00:00Z
updated: 2026-06-18T00:00:00Z
---

# Human UAT — Phase 1: Recherche & Filtres

## Current Test

[awaiting human testing]

## Tests

### 1. Recherche globale "Nutella" en moins de 3 secondes
expected: SearchScreen s'ouvre, les résultats de toutes les catégories apparaissent en moins de 3 secondes
result: [pending]

### 2. Autocomplétion après 2 caractères
expected: Un overlay de suggestions de marques apparaît (ex: "Nutella", "Nutrexpa"...) après avoir tapé "Nu" et attendu 300ms
result: [pending]

### 3. Historique persistant entre sessions
expected: "Nutella" apparaît dans la liste des recherches récentes après fermeture et réouverture de l'app
result: [pending]

### 4. Filtres réduisent visiblement les résultats
expected: La liste se réduit aux rappels graves ; un chip "Grave" apparaît sous la SearchBar
result: [pending]

### 5. Badge NON LU disparaît et persiste
expected: Le badge "NON LU" disparaît après ouverture de la fiche ; persistance confirmée au relancement
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
