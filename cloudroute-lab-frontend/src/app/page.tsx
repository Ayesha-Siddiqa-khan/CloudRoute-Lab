"use client";

import { useEffect, useState } from "react";

const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL || "";

interface HealthData {
  status: string;
  environment: string;
}

interface TrafficStep {
  step: number;
  component: string;
  description: string;
}

interface ConceptItem {
  name: string;
  description: string;
  use_case: string;
  status: string;
}

export default function Home() {
  const [health, setHealth] = useState<HealthData | null>(null);
  const [traffic, setTraffic] = useState<TrafficStep[]>([]);
  const [services, setServices] = useState<ConceptItem[]>([]);
  const [workloads, setWorkloads] = useState<ConceptItem[]>([]);
  const [error, setError] = useState(false);

  useEffect(() => {
    const fetchAll = async () => {
      try {
        const [healthRes, trafficRes, servicesRes, workloadsRes] = await Promise.all([
          fetch(`${API_BASE}/health`),
          fetch(`${API_BASE}/api/traffic-flow`),
          fetch(`${API_BASE}/api/concepts/services`),
          fetch(`${API_BASE}/api/concepts/workloads`),
        ]);

        if (!healthRes.ok || !trafficRes.ok || !servicesRes.ok || !workloadsRes.ok) {
          setError(true);
          return;
        }

        setHealth(await healthRes.json());
        const trafficData = await trafficRes.json();
        setTraffic(trafficData.flow);
        const servicesData = await servicesRes.json();
        setServices(servicesData.services);
        const workloadsData = await workloadsRes.json();
        setWorkloads(workloadsData.workloads);
      } catch {
        setError(true);
      }
    };

    fetchAll();
  }, []);

  return (
    <main className="min-h-screen px-6 py-12 max-w-6xl mx-auto">
      {/* Header */}
      <header className="text-center mb-16">
        <h1 className="text-4xl font-bold tracking-tight mb-3">
          <span className="text-blue-400">Cloud</span>Route{" "}
          <span className="text-cyan-400">Lab</span>
        </h1>
        <p className="text-gray-400 text-lg">
          Hands-on Kubernetes Networking & Storage Dashboard
        </p>
      </header>

      {/* Health Status */}
      <section className="mb-16">
        <h2 className="text-xl font-semibold mb-4 text-gray-200">Backend Status</h2>
        <div className="rounded-xl border border-gray-800 bg-gray-900/50 p-6">
          {error ? (
            <div className="flex items-center gap-3">
              <span className="w-3 h-3 rounded-full bg-red-500 animate-pulse" />
              <span className="text-red-400">
                Backend unreachable - start the FastAPI server on port 8000
              </span>
            </div>
          ) : health ? (
            <div className="flex items-center gap-6">
              <div className="flex items-center gap-3">
                <span className="w-3 h-3 rounded-full bg-green-500" />
                <span className="text-green-400 font-medium capitalize">{health.status}</span>
              </div>
              <span className="text-gray-500">|</span>
              <span className="text-gray-400">
                Environment: <span className="text-gray-200">{health.environment}</span>
              </span>
            </div>
          ) : (
            <div className="flex items-center gap-3">
              <span className="w-3 h-3 rounded-full bg-yellow-500 animate-pulse" />
              <span className="text-yellow-400">Loading...</span>
            </div>
          )}
        </div>
      </section>

      {/* Traffic Flow */}
      <section className="mb-16">
        <h2 className="text-xl font-semibold mb-4 text-gray-200">Traffic Flow</h2>
        <div className="rounded-xl border border-gray-800 bg-gray-900/50 p-6">
          <div className="flex flex-col sm:flex-row items-start sm:items-center gap-3 sm:gap-0">
            {traffic.map((item, i) => (
              <div key={item.step} className="flex items-center gap-3">
                <div className="flex flex-col items-center">
                  <div className="w-10 h-10 rounded-lg bg-blue-500/20 border border-blue-500/40 flex items-center justify-center text-blue-400 text-sm font-bold">
                    {item.step}
                  </div>
                  <span className="text-xs text-gray-300 mt-1 font-medium">{item.component}</span>
                  <span className="text-[10px] text-gray-500 mt-0.5 max-w-[100px] text-center leading-tight">
                    {item.description}
                  </span>
                </div>
                {i < traffic.length - 1 && (
                  <svg
                    className="w-6 h-6 text-gray-600 hidden sm:block"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                  </svg>
                )}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Service Types */}
      <section className="mb-16">
        <h2 className="text-xl font-semibold mb-4 text-gray-200">Service Types</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {services.map((svc) => (
            <div
              key={svc.name}
              className="rounded-xl border border-gray-800 bg-gray-900/50 p-5 hover:border-gray-700 transition-colors"
            >
              <div className="flex items-center justify-between mb-2">
                <h3 className="text-lg font-semibold text-gray-100">{svc.name}</h3>
                <span className="text-[10px] uppercase tracking-wider px-2 py-0.5 rounded-full bg-green-500/10 text-green-400 border border-green-500/20">
                  {svc.status}
                </span>
              </div>
              <p className="text-gray-400 text-sm mb-2">{svc.description}</p>
              <p className="text-gray-500 text-xs">
                <span className="text-gray-400 font-medium">Use case:</span> {svc.use_case}
              </p>
            </div>
          ))}
        </div>
      </section>

      {/* Workloads & Patterns */}
      <section className="mb-16">
        <h2 className="text-xl font-semibold mb-4 text-gray-200">Workloads & Patterns</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {workloads.map((wk) => (
            <div
              key={wk.name}
              className="rounded-xl border border-gray-800 bg-gray-900/50 p-5 hover:border-gray-700 transition-colors"
            >
              <div className="flex items-center justify-between mb-2">
                <h3 className="text-lg font-semibold text-gray-100">{wk.name}</h3>
                <span className="text-[10px] uppercase tracking-wider px-2 py-0.5 rounded-full bg-green-500/10 text-green-400 border border-green-500/20">
                  {wk.status}
                </span>
              </div>
              <p className="text-gray-400 text-sm mb-2">{wk.description}</p>
              <p className="text-gray-500 text-xs">
                <span className="text-gray-400 font-medium">Use case:</span> {wk.use_case}
              </p>
            </div>
          ))}
        </div>
      </section>

      {/* Footer */}
      <footer className="text-center text-gray-600 text-sm pt-8 border-t border-gray-800">
        CloudRoute Lab - Learn Kubernetes networking, storage & workloads
      </footer>
    </main>
  );
}
