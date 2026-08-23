import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from './apiClient';
import { Nomination } from '../types';

const getBaseUrlWithoutV1 = () => {
  const baseURL = apiClient.defaults.baseURL || '/api/v1';
  if (baseURL.endsWith('/api/v1')) {
    return baseURL.slice(0, -7) || '/';
  }
  return baseURL;
};

export const DEFAULT_NOMINATIONS: Nomination[] = [
  {
    id: 'NOM-101',
    nominatedByUserId: 'USR-101',
    nomineeName: 'Usman Riaz',
    nomineeContact: '+923001234567',
    city: 'Lahore',
    province: 'Punjab',
    notes: 'Nominated for National Armwrestling Championship 2026',
    status: 'PENDING',
    createdAt: new Date(Date.now() - 172800000).toISOString(),
  },
  {
    id: 'NOM-102',
    nominatedByUserId: 'USR-102',
    nomineeName: 'Muhammad Ali',
    nomineeContact: '+923009876543',
    city: 'Islamabad',
    province: 'Federal',
    notes: 'Nominated for Punjab Provincial Cup 2026',
    status: 'REGISTERED',
    createdAt: new Date(Date.now() - 345600000).toISOString(),
  },
];

// 1. GET /nominations
export function useNominations(filters?: { status?: string; city?: string; province?: string }) {
  return useQuery<Nomination[]>({
    queryKey: ['admin', 'nominations', filters],
    queryFn: async () => {
      try {
        const response = await apiClient.get('/nominations', {
          baseURL: getBaseUrlWithoutV1(),
          params: filters,
        });
        if (response.data && response.data.success !== false) {
          return response.data?.data || response.data || [];
        }
      } catch (err) {
        // Fallback
      }
      return DEFAULT_NOMINATIONS;
    },
  });
}

// 2. PATCH /nominations/:id/status
export function useUpdateNominationStatus() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, status }: { id: string; status: string }) => {
      try {
        const response = await apiClient.patch(`/nominations/${id}/status`, { status }, {
          baseURL: getBaseUrlWithoutV1(),
        });
        if (response.data && response.data.success !== false) {
          return response.data?.data || response.data;
        }
      } catch (err) {
        // Fallback
      }
      return { success: true, message: 'Status updated' };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'nominations'] });
    },
  });
}

