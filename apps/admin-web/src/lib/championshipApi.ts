import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient, unwrapMutationData } from './apiClient';
import { ChampionshipTitle, ChampionshipChallenge, CreateTitlePayload } from '../types';

export function useActiveTitles() {
  return useQuery<ChampionshipTitle[]>({
    queryKey: ['admin', 'championships', 'titles'],
    queryFn: async () => {
      const response = await apiClient.get('/championships/titles');
      const payload = unwrapMutationData(response);
      if (!Array.isArray(payload)) {
        throw new Error('Invalid championship titles payload from server.');
      }
      return payload as ChampionshipTitle[];
    },
  });
}

export function usePendingChallenges() {
  return useQuery<ChampionshipChallenge[]>({
    queryKey: ['admin', 'championships', 'challenges', 'PENDING'],
    queryFn: async () => {
      const response = await apiClient.get('/championships/challenges', {
        params: { status: 'PENDING' },
      });
      const payload = unwrapMutationData(response);
      if (!Array.isArray(payload)) {
        throw new Error('Invalid challenges payload from server.');
      }
      return payload as ChampionshipChallenge[];
    },
  });
}

export function useAcceptChallenge() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (challengeId: string) => {
      const response = await apiClient.post(`/championships/challenges/${challengeId}/accept`);
      return unwrapMutationData(response);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'championships'] });
    },
  });
}

export function useDeclineChallenge() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (challengeId: string) => {
      const response = await apiClient.post(`/championships/challenges/${challengeId}/decline`);
      return unwrapMutationData(response);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'championships'] });
    },
  });
}

export function useVacateTitle() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ titleId, reason }: { titleId: string; reason: 'VACATED' | 'STRIPPED' }) => {
      const response = await apiClient.post('/championships/vacate', { titleId, reason });
      return unwrapMutationData(response);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'championships'] });
    },
  });
}

export function useCreateTitle() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (payload: CreateTitlePayload) => {
      const response = await apiClient.post('/championships/titles', payload);
      return unwrapMutationData(response);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'championships'] });
    },
  });
}
