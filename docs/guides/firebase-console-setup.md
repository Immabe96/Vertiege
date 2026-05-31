# Firebase Setup Guide — Step by Step

This guide walks you through connecting Firebase to Vertiege. You only need to do this once.

---

## What You Need

- A Google account (your `ltyl.naughty@gmail.com` works)
- The Vertiege project folder open
- About 15 minutes

---

## Step 1: Go to Firebase Console

1. Open your browser and go to: https://console.firebase.google.com
2. Sign in with your Google account
3. Click the big **"+ Create a project"** button (or "Add project")
4. Name it: `Vertiege` (or `vertiege-app`)
5. Click **Continue**
6. You can turn OFF Google Analytics for now (you can add it later if needed)
7. Click **Create project** and wait for it to finish (~30 seconds)
8. Click **Continue** when it says "Your new project is ready"

---

## Step 2: Register Your Android App

1. On the project dashboard, click the **Android icon** (the little robot)
2. Fill in:
   - **Android package name**: `com.vertiege` (must match `applicationId` in `android/app/build.gradle.kts`)
   - **App nickname**: `Vertiege`
   - **Debug signing certificate SHA-1**: Required for Google Sign-In on device — see [plan/PACKAGE_ID_COM_VERTIEGE.md](plan/PACKAGE_ID_COM_VERTIEGE.md)
3. Click **Register app**
4. Download the `google-services.json` file
5. Put this file exactly here:
   ```
   android/app/google-services.json
   ```
   (NOT in `android/` — it must be in `android/app/`)

---

## Step 3: Skip the "Add Firebase SDK" Steps

The CLI output will tell you to edit `build.gradle` files. **You can skip this** — the Vertiege project already has the Firebase dependencies configured. The `google-services.json` is the only file you need to add.

---

## Step 4: Enable the Services

In the Firebase Console, click **"Build"** in the left sidebar, then enable each of these:

### Crashlytics
1. Click **Crashlytics** under "Build"
2. Click **"Get started"**
3. Select **Android** (skip iOS for now)
4. **SKIP** the SDK setup steps (already done in code)
5. Click **"Next"** through the remaining steps until done

### Cloud Messaging (for push notifications)
1. Click **Cloud Messaging** under "Build"
2. Click **"Get started"**
3. This enables FCM automatically — no further steps needed unless you want to send test notifications

### Remote Config
1. Click **Remote Config** under "Build"  
2. Click **"Get started"**
3. Don't add any parameters yet — the app code sets defaults

---

## Step 5: Verify It Works

1. Open PowerShell in the Vertiege folder
2. Run the app in debug mode:
   ```
   flutter run
   ```
3. Force a test crash by tapping **Settings → Crash Test** (or wherever the crash test button is)
4. In Firebase Console, go to **Crashlytics** → you should see the test crash appear within a minute
5. In Firebase Console, go to **Analytics** → **Dashboard** → you should see "first_open" event

---

## Step 6: Supabase Edge Function (for push notifications)

If you want push notifications to actually send, you need to create a Supabase Edge Function:

1. Install Supabase CLI:
   ```
   npm install -g supabase
   ```
2. Login:
   ```
   supabase login
   ```
3. Create the function:
   ```
   supabase functions new notify
   ```
4. The function should read from `device_tokens` table in Supabase and send via FCM

This is optional for now — Phase 9 only requires Firebase to be initialized and Crashlytics running.

---

## Checkpoint: Did It Work?

- [ ] `google-services.json` is at `android/app/google-services.json`
- [ ] App builds and runs without Firebase errors in the console
- [ ] Firebase Console shows the app connected (blue dot in Crashlytics)
- [ ] A test crash appears in the Crashlytics dashboard

If any step fails, the most common issue is the `google-services.json` being in the wrong folder or the package name not matching.

---

## What you DO NOT need to do

- You do NOT need to touch `build.gradle` files (already configured)
- You do NOT need to create a separate Firebase project for iOS (reuse this one)
- You do NOT need a billing account (free tier is enough for development)
- You do NOT need to set up Authentication in Firebase (Supabase handles auth)
