# Translating Flamenco

Flamenco's text is written in English. Display text in the shell's QML is wrapped
in `I18n.tr("…")`, and each language has a catalog in `shell/assets/i18n/<code>.json`
that maps the English text to its translation. Anything a catalog doesn't have stays
in English, so a partial translation works fine.

## Adding a language

1. `python3 tools/i18n.py extract` writes every string to
   `shell/assets/i18n/template.json` (English → "").
2. Copy it to `shell/assets/i18n/<code>.json` (the two-letter code: `de`, `fr`, `pt`…)
   and fill in the translations. Keep leading and trailing spaces: many strings are
   pieces joined with other text (`"Add "`, `"Pairing with "`).
3. Add the language to `languages` in `shell/Commons/I18n.qml`, as it calls itself
   (`{ value: "de", label: "Deutsch" }`).
4. `python3 tools/i18n.py check <code>` shows how much is done.

Choose it in Settings → Region & Language → Flamenco's language. Dates, day and
month names follow the language too.

## New text in the code

Write it in English and wrap it: `title: I18n.tr("Night light")`.
`python3 tools/i18n.py wrap` wraps plain string values of display properties
(`text`, `title`, `subtitle`, `label`, `placeholder`…) that were missed; it leaves
wrapped text alone, so it's safe to run again. Text built from several pieces
(`I18n.tr("Pairing with ") + name`) translates piece by piece.
