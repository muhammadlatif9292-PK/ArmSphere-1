import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient, unwrapMutationData } from './apiClient';
import { Dispute } from '../types';

export function useDisputes() {
  return useQuery<Dispute[]>({
    queryKey: ['admin', 'disputes'],
    queryFn: async () => {
      const response = await apiClient.get('/admin/disputes');
      const payload = unwrapMutationData(response);
      if (!Array.isArray(payload)) {
        throw new Error('Invalid disputes payload from server.');
      }
      return payload as Dispute[];
    },
  });
}

export function useResolveDispute() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, resolutionDetails, decision }: { id: string; resolutionDetails: string; decision: string }) => {
      const response = await apiClient.post(`/admin/disputes/${id}/resolve`, {
        resolutionDetails,
        decision,
      });
      return unwrapMutationData(response);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'disputes'] });
    },
  });
}
