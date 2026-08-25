import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient, unwrapMutationData } from './apiClient';
import { PendingCommunityPost } from '../types';

export function usePendingSubmissions() {
  return useQuery<PendingCommunityPost[]>({
    queryKey: ['admin', 'community', 'links', 'pending'],
    queryFn: async () => {
      const response = await apiClient.get('/community/links/pending');
      const payload = unwrapMutationData(response);
      if (!Array.isArray(payload)) {
        throw new Error('Invalid pending links payload from server.');
      }
      return payload as PendingCommunityPost[];
    },
  });
}

export function useModerateSubmission() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, decision }: { id: string; decision: 'APPROVED' | 'REJECTED' }) => {
      const response = await apiClient.post(`/community/links/${id}/moderate`, { decision });
      return unwrapMutationData(response);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'community', 'links'] });
    },
  });
}
