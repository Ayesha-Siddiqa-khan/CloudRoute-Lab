# CloudRoute Lab Backend

FastAPI backend powering the CloudRoute Lab Kubernetes learning dashboard.

## Tech Stack

- **FastAPI** — High-performance Python web framework
- **Python 3.10+**
- **Uvicorn** — ASGI server

## Local Setup

```bash
cd cloudroute-lab-backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
uvicorn main:app --reload --port 8000
```

API docs available at `http://localhost:8000/docs`.

## Endpoints

| Method | Path                      | Description                      |
|--------|---------------------------|----------------------------------|
| GET    | `/health`                 | Health check                     |
| GET    | `/api/status`             | Application status               |
| GET    | `/api/concepts/services`  | Kubernetes service types         |
| GET    | `/api/concepts/workloads` | Kubernetes workloads & patterns  |
| GET    | `/api/traffic-flow`       | Traffic flow steps               |

## Environment Variables

| Variable                | Default                  | Description                     |
|-------------------------|--------------------------|---------------------------------|
| `APP_ENV`               | `local`                  | Runtime environment             |
| `ALLOWED_ORIGINS`       | `http://localhost:3000`   | Comma-separated CORS origins    |
| `EXTERNAL_SERVICE_ALIAS`| `external-api.local`      | External service DNS alias      |
