import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient, unwrapMutationData } from './apiClient';
import { Venue } from '../types';

export function useVenues() {
  return useQuery<Venue[]>({
    queryKey: ['admin', 'venues'],
    queryFn: async () => {
      const response = await apiClient.get('/venues');
      const payload = unwrapMutationData(response);
      if (!Array.isArray(payload)) {
        throw new Error('Invalid venues payload from server.');
      }
      return payload as Venue[];
    },
  });
}

export function useVerifyVenue() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (venueId: string) => {
      const response = await apiClient.post(`/venues/${venueId}/verify`);
      return unwrapMutationData(response);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'venues'] });
    },
  });
}
