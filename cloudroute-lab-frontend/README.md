# CloudRoute Lab Frontend

Next.js TypeScript dashboard for the CloudRoute Lab Kubernetes learning project.

## Tech Stack

- **Next.js 14** — React framework with App Router
- **TypeScript** — Type-safe code
- **Tailwind CSS** — Utility-first styling

## Local Setup

```bash
cd cloudroute-lab-frontend
npm install
cp .env.example .env.local
npm run dev
```

Open `http://localhost:3000` in your browser.

## Environment Variables

| Variable                 | Default                  | Description                          |
|--------------------------|--------------------------|--------------------------------------|
| `NEXT_PUBLIC_API_BASE_URL` | `http://localhost:8000`  | FastAPI backend base URL             |

## Project Structure

```
src/app/
  layout.tsx   — Root layout & metadata
  page.tsx     — Dashboard (single page)
  globals.css  — Base styles & Tailwind
```
