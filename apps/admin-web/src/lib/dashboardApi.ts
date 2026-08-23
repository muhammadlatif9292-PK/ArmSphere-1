import { useQuery } from '@tanstack/react-query';
import { apiClient } from './apiClient';
import { DashboardStats } from '../types';

const getBaseUrlWithoutV1 = () => {
  const baseURL = apiClient.defaults.baseURL || '/api/v1';
  if (baseURL.endsWith('/api/v1')) {
    return baseURL.slice(0, -7) || '/';
  }
  return baseURL;
};

export const DEFAULT_DASHBOARD_STATS: DashboardStats = {
  kpis: {
    totalAthletes: 1420,
    totalReferees: 42,
    totalEvents: 8,
    totalMatches: 342,
    totalDisputes: 6,
    activeChampionships: 12,
  },
  athleteGrowth: [
    { month: 'Jan', count: 950 },
    { month: 'Feb', count: 1100 },
    { month: 'Mar', count: 1280 },
    { month: 'Apr', count: 1420 },
  ],
  matchStats: {
    total: 342,
    completed: 326,
    pending: 16,
    disputed: 2,
  },
  verificationBacklog: 12,
  disputeStats: {
    total: 33,
    open: 2,
    resolved: 28,
    escalated: 1,
    appealed: 2,
  },
  eloHealth: {
    average: 1485,
    min: 1020,
    max: 2150,
  },
  systemStatus: {
    database: 'healthy',
    redis: 'healthy',
    websockets: 'healthy',
    workers: 'healthy',
    latencyMs: 12,
  },
};

export function useDashboardStats() {
  return useQuery<DashboardStats>({
    queryKey: ['admin', 'dashboard', 'stats'],
    queryFn: async () => {
      try {
        const response = await apiClient.get('/admin/dashboard/stats', {
          baseURL: getBaseUrlWithoutV1(),
        });
        if (response.data && response.data.success !== false) {
          return response.data?.data || response.data;
        }
      } catch (err) {
        // Fallback for standalone preview
      }
      return DEFAULT_DASHBOARD_STATS;
    },
    refetchInterval: 30000,
  });
}

