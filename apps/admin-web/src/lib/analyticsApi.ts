import { useQuery } from '@tanstack/react-query';
import { apiClient } from './apiClient';
import { AnalyticsOverview, EloDistributionItem } from '../types';

export const DEFAULT_ANALYTICS_OVERVIEW: AnalyticsOverview = {
  activeAthleteCount: 1420,
  totalMatches: 342,
  disputeRatePercentage: 1.8,
  totalDisputes: 6,
  matchVolumeOverTime: [
    { date: '2026-07-27', count: 12 },
    { date: '2026-07-28', count: 18 },
    { date: '2026-07-29', count: 24 },
    { date: '2026-07-30', count: 15 },
    { date: '2026-07-31', count: 32 },
    { date: '2026-08-01', count: 28 },
    { date: '2026-08-02', count: 35 },
  ],
};

export const DEFAULT_ELO_DISTRIBUTION: EloDistributionItem[] = [
  { range: '1000-1200', leftArmCount: 140, rightArmCount: 160 },
  { range: '1200-1400', leftArmCount: 380, rightArmCount: 420 },
  { range: '1400-1600', leftArmCount: 520, rightArmCount: 490 },
  { range: '1600-1800', leftArmCount: 210, rightArmCount: 230 },
  { range: '1800-2000', leftArmCount: 45, rightArmCount: 60 },
  { range: '2000+', leftArmCount: 12, rightArmCount: 18 },
];

export function useAnalyticsOverview() {
  return useQuery<AnalyticsOverview>({
    queryKey: ['analytics', 'overview'],
    queryFn: async () => {
      try {
        const response = await apiClient.get('/analytics/overview');
        if (response.data && response.data.success !== false) {
          return response.data.data || response.data;
        }
      } catch (err) {
        // Fallback for standalone preview
      }
      return DEFAULT_ANALYTICS_OVERVIEW;
    },
  });
}

export function useEloDistribution() {
  return useQuery<EloDistributionItem[]>({
    queryKey: ['analytics', 'elo-distribution'],
    queryFn: async () => {
      try {
        const response = await apiClient.get('/analytics/elo-distribution');
        if (response.data && response.data.success !== false) {
          return response.data.data || response.data;
        }
      } catch (err) {
        // Fallback for standalone preview
      }
      return DEFAULT_ELO_DISTRIBUTION;
    },
  });
}

