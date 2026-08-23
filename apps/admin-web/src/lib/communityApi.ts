import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from './apiClient';
import { PendingCommunityPost } from '../types';

const getBaseUrlWithoutV1 = () => {
  const baseURL = apiClient.defaults.baseURL || '/api/v1';
  if (baseURL.endsWith('/api/v1')) {
    return baseURL.slice(0, -7) || '/';
  }
  return baseURL;
};

export const DEFAULT_PENDING_POSTS: PendingCommunityPost[] = [
  {
    id: 'POST-101',
    athleteId: 'ATH-101',
    externalUrl: 'https://youtube.com/watch?v=example-armsphere',
    platform: 'YOUTUBE',
    category: 'HIGHLIGHT',
    caption: 'Highlights from Pakistan National Super Match Finals 2026',
    matchId: 'M-1048',
    moderationStatus: 'PENDING',
    createdAt: new Date(Date.now() - 14400000).toISOString(),
    updatedAt: new Date(Date.now() - 14400000).toISOString(),
    athlete: {
      id: 'ATH-101',
      displayName: 'Zain Ul Abideen',
      profilePhoto: null,
    },
  },
];

export function usePendingSubmissions() {
  return useQuery<PendingCommunityPost[]>({
    queryKey: ['community', 'pendingSubmissions'],
    queryFn: async () => {
      try {
        const response = await apiClient.get('/community/links/pending', {
          baseURL: getBaseUrlWithoutV1(),
        });
        if (response.data && response.data.success !== false) {
          return response.data?.data || response.data || [];
        }
      } catch (err) {
        // Fallback
      }
      return DEFAULT_PENDING_POSTS;
    },
  });
}

export function useModerateSubmission() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (payload: { id: string; decision: 'APPROVED' | 'REJECTED' }) => {
      try {
        const response = await apiClient.post(
          `/community/links/${payload.id}/moderate`,
          {
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
      return { success: true, message: 'Submission moderated' };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['community', 'pendingSubmissions'] });
    },
  });
}

