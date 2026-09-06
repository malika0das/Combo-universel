# Play Console → Data Safety answers

Answer the form exactly like this for the current code.

## Does your app collect or share any of the required user data types?
**Yes** — only via the advertising SDK.

| Data type | Collected | Shared | Purpose | Optional? |
|---|---|---|---|---|
| Device or other IDs (Advertising ID) | Yes | Yes (Google AdMob) | Advertising or marketing; Analytics | Users can opt out of personalised ads in Settings |
| Approximate location | No | No | — | — |
| Personal info (name, email, phone) | No | No | — | — |
| Photos, files, contacts, messages | No | No | — | — |
| App activity (searches) | No | No | Stored on device only, never transmitted | — |

## Security practices
- Data is encrypted in transit: **Yes** (HTTPS only; cleartext disabled in the manifest).
- Users can request data deletion: **Yes** — all app data is local; uninstalling or clearing app storage deletes it. In-app "Clear" removes recent searches.
- Committed to Play Families Policy: **No** (target audience 18+).
- Independent security review: No.

## Permissions declared and why
| Permission | Why |
|---|---|
| `INTERNET` | Download list updates, serve ads |
| `ACCESS_NETWORK_STATE` | Detect offline state so updates fail gracefully |
| `com.google.android.gms.permission.AD_ID` | Required by AdMob on Android 13+ |

No sensitive permissions (no location, camera, storage, contacts, SMS, QUERY_ALL_PACKAGES, or foreground service) are requested — this avoids Play's declaration forms entirely.
