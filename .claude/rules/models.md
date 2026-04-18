---
path: "lib/app/models/**/*.dart"
description: "Eloquent-style model shape — fillable, casts, fromMap factory"
---

# Models

- Declare in this order: `table`, `resource`, `incrementing`, `fillable`, `casts`. Keep `fillable` snake_case — it mirrors the Laravel Resource payload.
- `incrementing` is `false` for UUID / string primary keys (every Uptizm domain model today). When false, also override `String get id => getAttribute('id')?.toString() ?? '';`.
- Use `EnumCast(E.values)` in `casts` for every backed enum column; it handles both directions. Do not parse enums manually inside getters when a cast covers it.
- `DateTime` casts go through `'datetime'` string — but when the wire value may arrive as `String | DateTime` (broadcast payloads), write a defensive getter: `if (raw is String) return DateTime.tryParse(raw); if (raw is DateTime) return raw; return null;`.
- List / Map getters never return nullable collections — coerce to `const []` / `const {}` when the attribute is absent or the wrong shape. Use `whereType<Map<String, dynamic>>()` before mapping nested lists.
- Typed scalar getters: `getAttribute('key') as T?`. Bool columns read as `getAttribute('key') == true` so a missing key stays false rather than crashing on a null cast. Prefer `get<T>('key')` or `getOrDefault('key', fallback)` when you want the typed accessor to coerce and default in one step.
- Delta updates: use `isDirty('field')` + `getOriginal('field')` to emit only changed keys in `update()` payloads — avoid sending the entire fillable set.
- Factory is always: `static X fromMap(Map<String, dynamic> map) => X()..fill(map)..syncOriginal()..exists = map.containsKey('id');`. Keep the three cascades in that order — `syncOriginal` after `fill` is what marks the object clean, `exists` gates whether `save()` upserts.
- Hybrid lookups: `static Future<X?> find(id) => InteractsWithPersistence.findById<X>(id, X.new);` and `static Future<List<X>> all() => InteractsWithPersistence.allModels<X>(X.new);`. SQLite first, API fallback — never roll your own.
- Nested data classes (`IncidentEvent`, `StatusPageMonitor`, `CheckTiming`) are plain Dart classes, not `Model` subclasses. They expose their own `fromMap` factory but skip `fillable`/`casts`.
- Broadcast convenience: `static X fromJson(String json) => X.fromMap(jsonDecode(json) as Map<String, dynamic>);` — only add it when an event listener actually needs it.
