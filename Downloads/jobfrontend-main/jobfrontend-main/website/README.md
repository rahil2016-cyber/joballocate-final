# JobAllocate Website

This folder contains the responsive website conversion of the existing Flutter app, using:

- Next.js (App Router)
- Tailwind CSS
- Existing Laravel backend APIs (`/api/v1`)

## Folder Structure

- `src/components` reusable UI building blocks (logo, buttons, shell, guards)
- `src/pages` screen-level web page modules (landing, auth, job seeker, employer, about)
- `src/hooks` shared client hooks (`use-auth`)
- `src/services` API client and session persistence
- `src/styles` brand tokens (colors/radius)
- `src/app` route bindings for Next.js pages

## Routes Implemented

- `/` landing page (web splash)
- `/auth/login/job-seeker`
- `/auth/login/employer`
- `/auth/register`
- `/job-seeker/home`
- `/job-seeker/dashboard`
- `/job-seeker/profile`
- `/employer/dashboard`
- `/employer/home`
- `/employer/profile`
- `/about`

## Local Run

1. Install dependencies:
   - `npm install`
2. Set backend URL:
   - Copy `.env.example` to `.env.local`
   - Set `NEXT_PUBLIC_API_BASE_URL` (example: `http://127.0.0.1:8000/api/v1`)
3. Start dev server:
   - `npm run dev`
4. Open:
   - [http://localhost:3000](http://localhost:3000)

## Deploy (Vercel)

1. Import `website` folder as a Vercel project.
2. Add environment variable:
   - `NEXT_PUBLIC_API_BASE_URL=https://<your-backend-domain>/api/v1`
3. Deploy.
