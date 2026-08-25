import { useQuery } from '@tanstack/react-query';
import { apiClient } from './apiClient';
import { AnalyticsOverview, EloDistributionItem } from '../types';

export function useAnalyticsOverview() {
  return useQuery<AnalyticsOverview>({
    queryKey: ['analytics', 'overview'],
    queryFn: async () => {
      const response = await apiClient.get('/analytics/overview');
      const payload = response.data?.data ?? response.data;
      if (!payload) {
        throw new Error('Empty analytics overview payload from server.');
      }
      return payload as AnalyticsOverview;
    },
  });
}

export function useEloDistribution() {
  return useQuery<EloDistributionItem[]>({
    queryKey: ['analytics', 'elo-distribution'],
    queryFn: async () => {
      const response = await apiClient.get('/analytics/elo-distribution');
      const payload = response.data?.data ?? response.data;
      if (!Array.isArray(payload)) {
        throw new Error('Invalid ELO distribution payload from server.');
      }
      return payload as EloDistributionItem[];
    },
  });
}
