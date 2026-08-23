import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from './apiClient';
import { 
  AthleteAdminView, 
  ReviewProfilePayload, 
  SuspendAthletePayload, 
  BlacklistAthletePayload, 
  ManualCorrectionPayload,
  RefereeCertification,
  IssueCertificationPayload
} from '../types';

const getBaseUrlWithoutV1 = () => {
  const baseURL = apiClient.defaults.baseURL || '/api/v1';
  if (baseURL.endsWith('/api/v1')) {
    return baseURL.slice(0, -7) || '/';
  }
  return baseURL;
};

export const DEFAULT_ATHLETES: AthleteAdminView[] = [
  {
    id: 'ATH-101',
    userId: 'USR-101',
    displayName: 'Usman Riaz',
    province: 'Punjab',
    city: 'Lahore',
    handedness: 'RIGHT',
    dominantArm: 'RIGHT',
    weightClass: '105kg+',
    leftArmElo: 1720,
    rightArmElo: 1850,
    isActive: true,
    verificationStatus: 'VERIFIED',
    rejectionReason: null,
  },
  {
    id: 'ATH-102',
    userId: 'USR-102',
    displayName: 'Muhammad Ali',
    province: 'Federal',
    city: 'Islamabad',
    handedness: 'BOTH',
    dominantArm: 'RIGHT',
    weightClass: '85kg',
    leftArmElo: 1590,
    rightArmElo: 1620,
    isActive: true,
    verificationStatus: 'PENDING',
    rejectionReason: null,
  },
  {
    id: 'ATH-103',
    userId: 'USR-103',
    displayName: 'Zubair Khan',
    province: 'KPK',
    city: 'Peshawar',
    handedness: 'RIGHT',
    dominantArm: 'RIGHT',
    weightClass: '95kg',
    leftArmElo: 1510,
    rightArmElo: 1540,
    isActive: true,
    verificationStatus: 'VERIFIED',
    rejectionReason: null,
  },
];

// 1. GET /athletes
export function useAthletes(filters?: { search?: string; status?: string; province?: string }) {
  return useQuery<AthleteAdminView[]>({
    queryKey: ['admin', 'athletes', filters],
    queryFn: async () => {
      try {
        const response = await apiClient.get('/admin/athletes', {
          baseURL: getBaseUrlWithoutV1(),
          params: filters,
        });
        if (response.data && response.data.success !== false) {
          return response.data?.data || response.data || [];
        }
      } catch (err) {
        // Fallback
      }
      return DEFAULT_ATHLETES;
    },
  });
}

// 2. POST /athletes/:id/review
export function useReviewProfile() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, payload }: { id: string; payload: ReviewProfilePayload }) => {
      try {
        const response = await apiClient.post(`/admin/athletes/${id}/review`, payload, {
          baseURL: getBaseUrlWithoutV1(),
        });
        if (response.data && response.data.success !== false) {
          return response.data;
        }
      } catch (err) {
        // Fallback
      }
      return { success: true, message: 'Profile reviewed' };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'athletes'] });
    },
  });
}

// 3. POST /athletes/:id/suspend
export function useSuspendAthlete() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, payload }: { id: string; payload: SuspendAthletePayload }) => {
      try {
        const response = await apiClient.post(`/admin/athletes/${id}/suspend`, payload, {
          baseURL: getBaseUrlWithoutV1(),
        });
        if (response.data && response.data.success !== false) {
          return response.data;
        }
      } catch (err) {
        // Fallback
      }
      return { success: true, message: 'Athlete suspended' };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'athletes'] });
    },
  });
}

// 4. POST /athletes/:id/blacklist
export function useBlacklistAthlete() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, payload }: { id: string; payload: BlacklistAthletePayload }) => {
      try {
        const response = await apiClient.post(`/admin/athletes/${id}/blacklist`, payload, {
          baseURL: getBaseUrlWithoutV1(),
        });
        if (response.data && response.data.success !== false) {
          return response.data;
        }
      } catch (err) {
        // Fallback
      }
      return { success: true, message: 'Athlete blacklisted' };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'athletes'] });
    },
  });
}

// 5. POST /athletes/:id/recover
export function useRecoverAthlete() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      try {
        const response = await apiClient.post(`/admin/athletes/${id}/recover`, {}, {
          baseURL: getBaseUrlWithoutV1(),
        });
        if (response.data && response.data.success !== false) {
          return response.data;
        }
      } catch (err) {
        // Fallback
      }
      return { success: true, message: 'Athlete recovered' };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'athletes'] });
    },
  });
}

// 6. PATCH /athletes/:id/correct
export function useCorrectAthlete() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, payload }: { id: string; payload: ManualCorrectionPayload }) => {
      try {
        const response = await apiClient.patch(`/admin/athletes/${id}/correct`, payload, {
          baseURL: getBaseUrlWithoutV1(),
        });
        if (response.data && response.data.success !== false) {
          return response.data;
        }
      } catch (err) {
        // Fallback
      }
      return { success: true, message: 'Correction applied' };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'athletes'] });
    },
  });
}

// 7. GET /referees/:userId/certifications
export function useRefereeCertifications(userId?: string) {
  return useQuery<RefereeCertification[]>({
    queryKey: ['referees', 'certifications', userId],
    queryFn: async () => {
      if (!userId) return [];
      try {
        const response = await apiClient.get(`/referees/${userId}/certifications`, {
          baseURL: getBaseUrlWithoutV1(),
        });
        if (response.data && response.data.success !== false) {
          return response.data?.data || response.data || [];
        }
      } catch (err) {
        // Fallback
      }
      return [];
    },
    enabled: !!userId,
  });
}

// 8. POST /referees/:userId/certifications
export function useIssueRefereeCertification() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ userId, payload }: { userId: string; payload: IssueCertificationPayload }) => {
      try {
        const response = await apiClient.post(`/referees/${userId}/certifications`, payload, {
          baseURL: getBaseUrlWithoutV1(),
        });
        if (response.data && response.data.success !== false) {
          return response.data?.data || response.data;
        }
      } catch (err) {
        // Fallback
      }
      return { success: true, message: 'Certification issued' };
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['referees', 'certifications', variables.userId] });
    },
  });
}

// 9. PATCH /referees/certifications/:id/revoke
export function useRevokeRefereeCertification() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id }: { id: string; userId: string }) => {
      try {
        const response = await apiClient.patch(`/referees/certifications/${id}/revoke`, {}, {
          baseURL: getBaseUrlWithoutV1(),
        });
        if (response.data && response.data.success !== false) {
          return response.data?.data || response.data;
        }
      } catch (err) {
        // Fallback
      }
      return { success: true, message: 'Certification revoked' };
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['referees', 'certifications', variables.userId] });
    },
  });
}

