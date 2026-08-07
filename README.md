# Qaari SL Staff

Internal Flutter app for **Production** uploaders and **Admin** reviewers.  
Separate from the consumer listener app (`qaari-sl-mobile`).

Brand: forest `#1B3A2E` / gold `#C9A24B` / cream `#F7F4EE` (Nunito).

## Roles

Sign in with Sanctum against `/api/staff` (seeded accounts):

| Email | Password | Role |
|-------|----------|------|
| `production@qaarisl.com` | `password` | Production — own reciters/uploads only |
| `reviewer@qaarisl.com` | `password` | Admin — review queue, approve/reject |
| `admin@qaarisl.com` | `password` | Super Admin — same review powers on mobile |

Production never sees the Reviews tab. Admins see Home, Reciters, Reviews, Account.

## Features (v1)

- Login / logout (token in `flutter_secure_storage`)
- Role dashboard counts
- Reciters create/edit + surah coverage list
- Upload / replace audio (`file_picker`) with progress → draft or submit
- Rejected: play voice notes, replace full surah, resubmit
- Admin reviews inbox → play, approve, or reject with mic (`record`)
- **Manual ayah sync** (Admin / Super Admin): mark ayah starts while listening, save progress / resume — same workflow as Filament

## Run

```bash
cd qaari-sl-backend
php artisan serve --host=0.0.0.0 --port=8000

cd qaari-sl-staff
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

### USB tethering (Samsung data → laptop)

Same notes as the consumer app:

1. Keep USB tethering on
2. On the PC, `ipconfig` → **Ethernet** / `SAMSUNG Mobile USB Remote NDIS` IPv4 (not Wi‑Fi)
3. Laravel: `php artisan serve --host=0.0.0.0 --port=8000`
4. Rebuild staff app (hot reload does **not** apply dart-defines):

```bash
flutter run --dart-define=API_BASE_URL=http://10.172.77.244:8000
```

(Replace with your tether IP.)

### Same Wi‑Fi

Use the PC Wi‑Fi IPv4 from `ipconfig` with the same `artisan serve --host=0.0.0.0`.

## API

All under `/api/staff` (see backend `feature/staff-api`):

- `POST /login` · `POST /logout` · `GET /me` · `GET /dashboard` · `GET /surahs`
- Reciters / recitations CRUD-ish + `submit` + `replace-audio`
- `GET /reviews` · `POST …/approve` · `POST …/reject` · `GET …/review-notes`

## Out of scope (v1)

User management, offline upload queue, store listing, consumer features (favorites / follow-along).
