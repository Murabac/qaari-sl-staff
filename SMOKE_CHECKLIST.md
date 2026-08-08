# Staff app — device smoke checklist

Use production API (`https://qaari.mahaysaa.com`) or local LAN.

## Accounts
| Role | Email | Notes |
|------|-------|--------|
| Production | production@… | Create / upload / submit |
| Admin | reviewer@… | Approve / reject + mic / ayah sync |
| Super Admin | admin@… | Full access |

## Pass criteria
- [ ] Login as Production
- [ ] Create or open a reciter (photo optional)
- [ ] Upload draft recitation (audio)
- [ ] Submit for review
- [ ] Login as Admin — see pending queue
- [ ] Reject with voice note OR approve
- [ ] If rejected: Production replaces audio and resubmits
- [ ] Admin opens **Manual ayah sync**, marks a few ayahs, Save
- [ ] Admin runs **Auto sync** from overflow menu (optional; needs FFmpeg on server)
- [ ] Approved track appears on public site / consumer app

## Build staff APK (internal)
```bash
cd qaari-sl-staff
flutter build apk --release
```
