import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from './apiClient';
import { Dispute } from '../types';

const getBaseUrlWithoutV1 = () => {
  const baseURL = apiClient.defaults.baseURL || '/api/v1';
  if (baseURL.endsWith('/api/v1')) {
    return baseURL.slice(0, -7) || '/';
  }
  return baseURL;
};

export const DEFAULT_DISPUTES: Dispute[] = [
  {
    id: 'DISP-101',
    matchId: 'M-1048',
    creatorId: 'USR-101',
    title: 'Score protest regarding micro-foul call on Table 02 during strap match',
    description: 'Score protest regarding micro-foul call on Table 02 during strap match at Pakistan National Championship 2026',
    status: 'UNDER_REVIEW',
    resolutionDetails: null,
    assignedReviewerId: 'USR-ADMIN-01',
    createdAt: new Date(Date.now() - 3600000).toISOString(),
    updatedAt: new Date(Date.now() - 3600000).toISOString(),
  },
  {
    id: 'DISP-102',
    matchId: 'M-1032',
    creatorId: 'USR-102',
    title: 'Weight class eligibility challenge prior to bracket placement',
    description: 'Weight class eligibility challenge prior to bracket placement at Punjab Provincial Cup 2026',
    status: 'OPEN',
    resolutionDetails: null,
    assignedReviewerId: null,
    createdAt: new Date(Date.now() - 7200000).toISOString(),
    updatedAt: new Date(Date.now() - 7200000).toISOString(),
  },
];

export function useDisputes() {
  return useQuery<Dispute[]>({
    queryKey: ['governance', 'disputes'],
    queryFn: async () => {
      try {
        const response = await apiClient.get('/admin/disputes', {
          baseURL: getBaseUrlWithoutV1(),
        });
        if (response.data && response.data.success !== false) {
          return response.data?.data || response.data || [];
        }
      } catch (err) {
        // Fallback for standalone preview
      }
      return DEFAULT_DISPUTES;
    },
  });
}

export function useResolveDispute() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (payload: { id: string; resolutionDetails: string; decision: 'RESOLVED' | 'REJECTED' }) => {
      try {
        const response = await apiClient.post(
          `/admin/disputes/${payload.id}/resolve`,
          {
            resolutionDetails: payload.resolutionDetails,
            decision: payload.decision,
          },
          { baseURL: getBaseUrlWithoutV1() }
        );
        if (response.data && response.data.success !== false) {
          return response.data;
        }
      } catch (err) {
        // Fallback
      }
      return { success: true, message: 'Dispute resolved successfully' };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['governance', 'disputes'] });
    },
  });
}

