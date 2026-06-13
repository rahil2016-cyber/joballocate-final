# Connect the app to Laravel on your PC

## 1. Run the API

From the project root:

```bash
cd backend
php artisan serve --host=0.0.0.0 --port=8000
```

Default URL: `http://127.0.0.1:8000/api/v1`.

## 1b. APK / shared testing (live server)

The app defaults to **`https://demo.covalinx.in/api/v1`**: on launch it **probes** the live `/jobs` endpoint; if it responds, that base URL is used. If the live host is down or unreachable, it falls back to **local dev** (`10.0.2.2:8000` on Android emulator, `127.0.0.1:8000` elsewhere).

- **Override** (always wins):  
  `flutter run --dart-define=API_BASE_URL=https://demo.covalinx.in/api/v1`  
  (Use HTTPS when your server has it; update `lib/config/api_config.dart` `liveProductionBase` if the default URL changes.)

- **iOS:** `Info.plist` allows HTTP to `demo.covalinx.in` for ATS; prefer HTTPS in production.

## 2. Android emulator

The emulator cannot use `localhost` to reach your PC. When the **live** probe fails, the app uses **`10.0.2.2:8000`** automatically (see `lib/config/api_config.dart`).

## 3. Physical Android device (same Wi‑Fi)

Use your PC’s LAN IP and pass it at build time:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.XXX:8000/api/v1
```

Run Laravel with `--host=0.0.0.0` so it listens on all interfaces.

## 4. Registration vs login

Use **Create account** on the login screens or **Register** from the home screen. Registration collects profile fields, then sends OTP with `intent: register`. **Companies** are **auto-verified** and new jobs **auto-publish** by default (`AUTO_VERIFY_NEW_COMPANIES=true` and `AUTO_PUBLISH_NEW_JOBS=true` in backend `.env` — see `config/joballocate.php`) until an admin panel enforces moderation. If those are `false`, new companies stay unverified and jobs stay **pending approval**. After editing `.env`, run `php artisan config:clear`.

**DB values (MySQL):** `companies.verification_status` is an **ENUM**: `unverified`, `pending`, `verified`, `rejected`. `job_posts.status` is an **ENUM**: `draft`, `pending_review`, `published`, `closed`, `rejected`. phpMyAdmin shows these as dropdowns — do not type free text. The mobile app maps these to labels like “Verified” / “Approved & live” (`lib/constants/employer_status_labels.dart`).

With `APP_DEBUG=true` in Laravel `.env`, `POST /auth/send-otp` returns `data.mock_otp` in the JSON. The app prefills that code when present.

**OTP troubleshooting:** On local, the API uses a **fixed code `123456`** by default (`config/otp.php`: `use_fixed_code` is true when `APP_ENV=local`). Phone numbers are normalized (digits only), so `+91 98765 43210` and `9876543210` match the same OTP. If you still see “Invalid OTP”, run `php artisan config:clear` and send a **new** code after changing `.env`. Do **not** reuse an old code after a failed verify (older builds used `Cache::pull` and removed the code on first attempt—fixed in backend).

For **login** only, the account must already exist (`intent: login`).

## 5. Job seeker (after login)

The home feed loads **`GET /jobs`** (no auth). **Profile** tab uses **`GET /job-seeker/profile`** and **`PUT /job-seeker/profile`** (headline, bio, skills, city, country, experience, expected salary, etc.). **Plans & packages** uses **`GET /job-seeker/packages/catalog`**, **`GET /job-seeker/packages/purchases`** (paginated activation history per account), and **`POST /job-seeker/packages/select`** to activate a plan (demo: confirm dialog in the app; no real payment). Current credits and expiry live on **`job_seeker_profiles`** (server); history rows are in **`seeker_package_purchases`** so purchases show after reinstall when the user logs in again. Profile returns **`applications_remaining`** / **`job_credits_expires_at`** and **`resume_builds_remaining`** / **`resume_credits_expires_at`** (separate tracks). Buying a **job-only** or **resume-only** plan updates only that track. **`POST /job-seeker/resume/one-off-purchase`** (demo **₹20**) adds one resume build when the user has no active resume credits. **Apply** requires an active package with applications left — **`POST /job-seeker/jobs/{id}/apply`**. **My Applications** uses **`GET /job-seeker/applications`** (includes `cover_letter`, `employer_note`). **Withdraw** an application while status is `applied` or `shortlisted` with **`DELETE /job-seeker/applications/{id}`** (refunds one application credit). **Resume AI** (OpenRouter): set **`MODEL_KEY`** in backend `.env` (no spaces around `=`). Default chat URL is **`https://openrouter.ai/api/v1/chat/completions`**. Test: **`php artisan openrouter:ping`** (after **`php artisan config:clear`**). If OpenRouter returns **404** with *“No endpoints available… guardrail… data policy”*, open **`https://openrouter.ai/settings/privacy`** and adjust **privacy / data policy** so your chosen free model is allowed. Default model in config: **`arcee-ai/trinity-large-preview:free`** (override with **`OPENROUTER_MODEL`** in `.env`). The app calls **`POST /job-seeker/resume/ai-assist`** (auth) — uses **one `resume_builds_remaining` credit** per successful generation. Employers see **`cover_letter`**, optional **`resume_url`** from the seeker profile, and can set **`employer_note`** when updating status via **`PATCH /company/job-posts/{jobId}/applications/{applicationId}`**.

Ensure Laravel is running and at least one job is **published** (employer creates a job — it should appear on the feed with defaults above).

## 6. Session persistence

The app saves the bearer token and user JSON with **SharedPreferences** after OTP login. On next launch, the splash screen sends **job seekers** to **Home** and **employers** to the **employer dashboard** when a valid session exists. Use **Log out** in Profile to clear storage.

## 7. Demo mode (no backend)

In `lib/services/api_service.dart`, set `ApiService.demoMode = true` to use offline demo OTP `123456`.
