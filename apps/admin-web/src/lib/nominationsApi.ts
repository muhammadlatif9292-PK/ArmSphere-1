import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient, unwrapMutationData } from './apiClient';
import { Nomination } from '../types';

export function useNominations() {
  return useQuery<Nomination[]>({
    queryKey: ['admin', 'nominations'],
    queryFn: async () => {
      const response = await apiClient.get('/nominations');
      const payload = unwrapMutationData(response);
      if (!Array.isArray(payload)) {
        throw new Error('Invalid nominations payload from server.');
      }
      return payload as Nomination[];
    },
  });
}

export function useUpdateNominationStatus() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, status }: { id: string; status: string }) => {
      const response = await apiClient.patch(`/nominations/${id}/status`, { status });
      return unwrapMutationData(response);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'nominations'] });
    },
  });
}
