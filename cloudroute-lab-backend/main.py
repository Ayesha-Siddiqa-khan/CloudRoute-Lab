import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

APP_ENV = os.getenv("APP_ENV", "local")
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000")
EXTERNAL_SERVICE_ALIAS = os.getenv("EXTERNAL_SERVICE_ALIAS", "external-api.local")

app = FastAPI(title="CloudRoute Lab API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS.split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "healthy", "environment": APP_ENV}


@app.get("/ready")
def ready():
    return {"status": "ready", "environment": APP_ENV}


@app.get("/status")
@app.get("/api/status")
def status():
    return {
        "app": "CloudRoute Lab",
        "version": "1.0.0",
        "environment": APP_ENV,
        "external_service_alias": EXTERNAL_SERVICE_ALIAS,
    }


@app.get("/concepts/services")
@app.get("/api/concepts/services")
def services():
    return {
        "services": [
            {
                "name": "ClusterIP",
                "description": "Internal-only service for pod-to-pod communication within the cluster.",
                "use_case": "Microservice internal APIs, database connections.",
                "status": "ready",
            },
            {
                "name": "NodePort",
                "description": "Exposes service on a static port on each node in the cluster.",
                "use_case": "Development access, quick external testing.",
                "status": "ready",
            },
            {
                "name": "LoadBalancer",
                "description": "Provisions an external load balancer (cloud provider) to route traffic to the service.",
                "use_case": "Production external traffic ingestion.",
                "status": "ready",
            },
            {
                "name": "ExternalName",
                "description": "Maps a service to an external DNS name, acting as a CNAME alias.",
                "use_case": "Referencing external databases, third-party APIs.",
                "status": "ready",
            },
        ]
    }


@app.get("/concepts/workloads")
@app.get("/api/concepts/workloads")
def workloads():
    return {
        "workloads": [
            {
                "name": "DaemonSet",
                "description": "Ensures one copy of a pod runs on every node (or a subset).",
                "use_case": "Logging agents, monitoring exporters, network plugins.",
                "status": "ready",
            },
            {
                "name": "StatefulSet",
                "description": "Manages stateful applications with stable network identity and persistent storage.",
                "use_case": "Databases, message queues, distributed stateful apps.",
                "status": "ready",
            },
            {
                "name": "Gateway API",
                "description": "Modern Kubernetes networking API for advanced routing, traffic splitting, and TLS.",
                "use_case": "Multi-protocol routing, traffic management, TLS termination.",
                "status": "ready",
            },
            {
                "name": "Init Containers",
                "description": "Run before the main container starts, performing setup or dependency checks.",
                "use_case": "Schema migrations, waiting for dependencies, config generation.",
                "status": "ready",
            },
            {
                "name": "Sidecars",
                "description": "Additional containers that run alongside the main application pod.",
                "use_case": "Service mesh proxies, log shipping, health monitoring.",
                "status": "ready",
            },
            {
                "name": "Persistent Volumes",
                "description": "Storage abstraction that decouples from pod lifecycle.",
                "use_case": "Database storage, shared file systems, model artifacts.",
                "status": "ready",
            },
        ]
    }


@app.get("/traffic-flow")
@app.get("/api/traffic-flow")
def traffic_flow():
    return {
        "flow": [
            {"step": 1, "component": "User", "description": "End user sends a request."},
            {"step": 2, "component": "DNS", "description": "Domain name resolves to IP address."},
            {"step": 3, "component": "Load Balancer", "description": "Cloud load balancer distributes traffic across nodes."},
            {"step": 4, "component": "Gateway API", "description": "Routes request based on host/path rules."},
            {"step": 5, "component": "Service", "description": "Kubernetes service selects target pods."},
            {"step": 6, "component": "Pod", "description": "Application pod processes the request."},
        ]
    }
