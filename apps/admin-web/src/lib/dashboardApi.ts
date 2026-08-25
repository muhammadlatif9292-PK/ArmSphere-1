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

export function useDashboardStats() {
  return useQuery<DashboardStats>({
    queryKey: ['admin', 'dashboard', 'stats'],
    queryFn: async () => {
      const response = await apiClient.get('/admin/dashboard/stats', {
        baseURL: getBaseUrlWithoutV1(),
      });
      // Backend wraps the payload as { success, data } — unwrap honestly.
      const payload = response.data?.data ?? response.data;
      if (!payload) {
        throw new Error('Empty dashboard stats payload from server.');
      }
      return payload as DashboardStats;
    },
    refetchInterval: 30000,
  });
}
