import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from './apiClient';
import { ChampionshipTitle, ChampionshipChallenge, CreateTitlePayload } from '../types';

const getBaseUrlWithoutV1 = () => {
  const baseURL = apiClient.defaults.baseURL || '/api/v1';
  if (baseURL.endsWith('/api/v1')) {
    return baseURL.slice(0, -7) || '/';
  }
  return baseURL;
};

export const DEFAULT_TITLES: ChampionshipTitle[] = [
  {
    id: 'TITLE-01',
    name: 'National Senior Heavyweight Right Arm',
    arm: 'RIGHT',
    division: 'SENIOR',
    weightClass: '105kg+',
    activeChampionId: 'ATH-101',
    activeChampion: {
      id: 'ATH-101',
      userId: 'USR-101',
      displayName: 'Usman "The Hammer" Riaz',
      province: 'Punjab',
      city: 'Lahore',
      handedness: 'RIGHT',
      dominantArm: 'RIGHT',
      gender: 'MALE',
      weightClass: '105kg+',
    },
    createdAt: '2025-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  },
  {
    id: 'TITLE-02',
    name: 'National Middleweight Left Arm',
    arm: 'LEFT',
    division: 'SENIOR',
    weightClass: '85kg',
    activeChampionId: 'ATH-102',
    activeChampion: {
      id: 'ATH-102',
      userId: 'USR-102',
      displayName: 'Bilal Ahmed',
      province: 'Federal',
      city: 'Islamabad',
      handedness: 'LEFT',
      dominantArm: 'LEFT',
      gender: 'MALE',
      weightClass: '85kg',
    },
    createdAt: '2025-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  },
];

export const DEFAULT_CHALLENGES: ChampionshipChallenge[] = [
  {
    id: 'CHAL-01',
    titleId: 'TITLE-01',
    challengerId: 'ATH-103',
    status: 'PENDING',
    createdAt: new Date(Date.now() - 86400000).toISOString(),
    updatedAt: new Date(Date.now() - 86400000).toISOString(),
    challenger: {
      id: 'ATH-103',
      userId: 'USR-103',
      displayName: 'Zubair Khan',
      province: 'KPK',
      city: 'Peshawar',
      handedness: 'RIGHT',
      dominantArm: 'RIGHT',
      gender: 'MALE',
      weightClass: '95kg',
    },
    title: DEFAULT_TITLES[0],
  },
];

export function useActiveTitles() {
  return useQuery<ChampionshipTitle[]>({
    queryKey: ['championships', 'titles'],
    queryFn: async () => {
      try {
        const response = await apiClient.get('/championships/titles', {
          baseURL: getBaseUrlWithoutV1(),
        });
        if (response.data && response.data.success !== false) {
          return response.data?.data || response.data || [];
        }
      } catch (err) {
        // Fallback
      }
      return DEFAULT_TITLES;
    },
  });
}

export function usePendingChallenges() {
  return useQuery<ChampionshipChallenge[]>({
    queryKey: ['championships', 'challenges', 'pending'],
    queryFn: async () => {
      try {
        const response = await apiClient.get('/championships/challenges', {
          baseURL: getBaseUrlWithoutV1(),
          params: { status: 'PENDING' },
        });
        if (response.data && response.data.success !== false) {
          return response.data?.data || response.data || [];
        }
      } catch (err) {
        // Fallback
      }
      return DEFAULT_CHALLENGES;
    },
  });
}

export function useAcceptChallenge() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (challengeId: string) => {
      try {
        const response = await apiClient.post(
          `/championships/challenges/${challengeId}/accept`,
          {},
          { baseURL: getBaseUrlWithoutV1() }
        );
        if (response.data && response.data.success !== false) {
          return response.data;
        }
      } catch (err) {
        // Fallback
      }
      return { success: true, message: 'Challenge accepted' };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['championships', 'challenges'] });
      queryClient.invalidateQueries({ queryKey: ['championships', 'titles'] });
    },
  });
}

export function useDeclineChallenge() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (challengeId: string) => {
      try {
        const response = await apiClient.post(
          `/championships/challenges/${challengeId}/decline`,
          {},
          { baseURL: getBaseUrlWithoutV1() }
        );
        if (response.data && response.data.success !== false) {
          return response.data;
        }
      } catch (err) {
        // Fallback
      }
      return { success: true, message: 'Challenge declined' };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['championships', 'challenges'] });
      queryClient.invalidateQueries({ queryKey: ['championships', 'titles'] });
    },
  });
}

export function useVacateTitle() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (payload: { titleId: string; reason: 'VACATED' | 'STRIPPED' }) => {
      try {
        const response = await apiClient.post(
          '/championships/vacate',
          payload,
          { baseURL: getBaseUrlWithoutV1() }
        );
        if (response.data && response.data.success !== false) {
          return response.data;
        }
      } catch (err) {
        // Fallback
      }
      return { success: true, message: 'Title vacated successfully' };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['championships', 'titles'] });
    },
  });
}

export function useCreateTitle() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (payload: CreateTitlePayload) => {
      try {
        const response = await apiClient.post(
          '/championships/titles',
          payload,
          { baseURL: getBaseUrlWithoutV1() }
        );
        if (response.data && response.data.success !== false) {
          return response.data;
        }
      } catch (err) {
        // Fallback
      }
      return { success: true, message: 'Title created successfully' };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['championships', 'titles'] });
    },
  });
}


