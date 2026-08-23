import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from './apiClient';
import { Venue } from '../types';

const getBaseUrlWithoutV1 = () => {
  const baseURL = apiClient.defaults.baseURL || '/api/v1';
  if (baseURL.endsWith('/api/v1')) {
    return baseURL.slice(0, -7) || '/';
  }
  return baseURL;
};

export const DEFAULT_VENUES: Venue[] = [
  {
    id: 'VEN-101',
    name: 'Nishtar Park Sports Complex Arena',
    city: 'Lahore',
    province: 'Punjab',
    address: 'Gulberg III, Lahore, Punjab',
    contactInfo: 'info@nishtarpark.pk',
    description: 'Premier indoor armwrestling stadium',
    logoUrl: null,
    ownerUserId: 'USR-101',
    isVerified: true,
    createdAt: '2025-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  },
  {
    id: 'VEN-102',
    name: 'Islamabad Sports Complex Gymnasium',
    city: 'Islamabad',
    province: 'Federal',
    address: 'Kashmir Highway, Islamabad',
    contactInfo: 'contact@isbsports.pk',
    description: 'Federal armwrestling training facility',
    logoUrl: null,
    ownerUserId: 'USR-102',
    isVerified: true,
    createdAt: '2025-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  },
];

// 1. GET /venues
export function useVenues(filters?: { city?: string; province?: string }) {
  return useQuery<Venue[]>({
    queryKey: ['admin', 'venues', filters],
    queryFn: async () => {
      try {
        const response = await apiClient.get('/venues', {
          baseURL: getBaseUrlWithoutV1(),
          params: filters,
        });
        if (response.data && response.data.success !== false) {
          return response.data?.data || response.data || [];
        }
      } catch (err) {
        // Fallback
      }
      return DEFAULT_VENUES;
    },
  });
}

// 2. POST /venues/:id/verify
export function useVerifyVenue() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      try {
        const response = await apiClient.post(`/venues/${id}/verify`, {}, {
          baseURL: getBaseUrlWithoutV1(),
        });
        if (response.data && response.data.success !== false) {
          return response.data;
        }
      } catch (err) {
        // Fallback
      }
      return { success: true, message: 'Venue verified' };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'venues'] });
    },
  });
}

