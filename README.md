# BasicUserApp

Flutter Android app + Node.js/Express backend.

## Repository layout

- `frontend/` — Flutter mobile application.
- `backend/` — Express REST API.
- `.github/workflows/flutter-ci-cd.yml` — GitHub Actions CI/CD pipeline.
- `render.yaml` — Render backend service blueprint.

## CI/CD behavior

The GitHub Actions workflow runs when code is pushed to `main`, a pull request targets `main`, or a `v*` tag is pushed.

1. Installs backend dependencies and checks the Node.js server syntax.
2. Runs `flutter analyze` and `flutter test`.
3. Builds a release APK.
4. Uploads the APK as a downloadable GitHub Actions artifact.
5. When a version tag such as `v1.0.1` is pushed, publishes the APK files as a GitHub Release.
6. If the `RENDER_DEPLOY_HOOK` GitHub secret is configured, a push to `main` also triggers a Render backend deployment.

The workflow can build with a debug signing key before release signing is configured. That is suitable for CI testing only. It is not a safe production update path.

## Required GitHub secrets

Open the repository on GitHub → **Settings → Secrets and variables → Actions → New repository secret**.

### Android signing (required to update existing installations)

Configure these four secrets:

- `ANDROID_KEYSTORE_BASE64` — Base64 contents of the same keystore that signed the APK already installed by users.
- `ANDROID_KEYSTORE_PASSWORD` — keystore password.
- `ANDROID_KEY_ALIAS` — key alias.
- `ANDROID_KEY_PASSWORD` — key password.

**Critical:** Android accepts an in-place APK update only when the new APK is signed by the same signing certificate as the installed APK (or a valid signing-key rotation is used). The private signing key cannot be recovered from an APK. The existing uploaded APK must be checked against the keystore on the original build machine. If that original key is unavailable, users will need to uninstall the old app (which may erase local app data) before installing a newly signed build, or you must use the original Play App Signing setup if the app was distributed through Play.

For a Windows machine, if the APK was signed with the default Android debug key, the likely keystore path is:

`%USERPROFILE%\.android\debug.keystore`

PowerShell command to copy its Base64 value:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\.android\debug.keystore")) | Set-Clipboard
```

Paste the copied value into the `ANDROID_KEYSTORE_BASE64` secret. The default debug key commonly uses alias `androiddebugkey` and password `android`, but verify that this is the key that signed the existing APK. Do not commit the keystore or passwords to Git.

### Render backend deployment (optional)

In Render, open the backend Web Service → Settings → Deploy Hook. Copy the hook URL and save it as the GitHub Actions secret `RENDER_DEPLOY_HOOK`.

The workflow triggers this hook on pushes to `main`. If Render is already connected to GitHub with automatic deploy enabled, do not configure the hook as well; otherwise duplicate deployments may occur.

## Release process

1. Update the `version` in `frontend/pubspec.yaml`. Example: `version: 1.0.1+2`.
   - Increase the number after `+` for every Android release. Android `versionCode` must always increase.
2. Commit and push to `main`. GitHub Actions tests and builds an APK artifact.
3. After the workflow succeeds, create and push a matching version tag:

```bash
git tag v1.0.1
git push origin v1.0.1
```

4. GitHub Actions creates a GitHub Release containing `app-release.apk`.
5. The app checks `GET /api/version` when it opens. If the backend reports a newer build, the app shows a download prompt and opens the release APK link.

## Configure the backend's update metadata

The existing backend already exposes `GET /api/version`. Set these Render environment variables for each release:

- `LATEST_APP_VERSION` — same version as `frontend/pubspec.yaml` before `+`, e.g. `1.0.1`.
- `LATEST_BUILD_NUMBER` — number after `+`, e.g. `2`.
- `APP_DOWNLOAD_URL` — `https://github.com/vnisanth20063/BasicUserApp/releases/latest/download/app-release.apk`
- `RELEASE_NOTES` — short user-facing description.

The Flutter app uses these values to decide whether to offer an update. The release link opens externally; Android still requires the user to download and approve installation of a sideloaded APK. Silent background installation is not available to ordinary apps.

For automatic Play Store updates, publish the AAB/APK to Google Play Console (internal/closed/production track). Google Play then manages updates for users who installed from Play Store. A sideloaded APK does not automatically become a Play Store installation.

## Current backend storage note

The backend in this ZIP currently stores registrations in `backend/data/users.json`; it is not connected to MongoDB yet. A Render free service's local filesystem should not be treated as durable database storage. Complete the MongoDB migration before relying on this backend for production user records.
