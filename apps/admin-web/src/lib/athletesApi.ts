import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient, unwrapMutationData } from './apiClient';
import { AthleteAdminView, RefereeCertification, IssueCertificationPayload } from '../types';

export function useAthletes(filters?: { search?: string; status?: string; province?: string }) {
  return useQuery<AthleteAdminView[]>({
    queryKey: ['admin', 'athletes', filters ?? {}],
    queryFn: async () => {
      const response = await apiClient.get('/admin/athletes', {
        params: {
          search: filters?.search || undefined,
          status: filters?.status || undefined,
          province: filters?.province || undefined,
        },
      });
      const payload = unwrapMutationData(response);
      if (!Array.isArray(payload)) {
        throw new Error('Invalid athletes payload from server.');
      }
      return payload as AthleteAdminView[];
    },
  });
}

export function useReviewProfile() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, payload }: { id: string; payload: { status: string; reason?: string } }) => {
      const response = await apiClient.post(`/admin/athletes/${id}/review`, payload);
      return unwrapMutationData(response);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'athletes'] });
    },
  });
}

export function useSuspendAthlete() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, payload }: { id: string; payload: { reason: string; durationDays?: number } }) => {
      const response = await apiClient.post(`/admin/athletes/${id}/suspend`, payload);
      return unwrapMutationData(response);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'athletes'] });
    },
  });
}

export function useBlacklistAthlete() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, payload }: { id: string; payload: { reason: string } }) => {
      const response = await apiClient.post(`/admin/athletes/${id}/blacklist`, payload);
      return unwrapMutationData(response);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'athletes'] });
    },
  });
}

export function useRecoverAthlete() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (athleteId: string) => {
      const response = await apiClient.post(`/admin/athletes/${athleteId}/recover`);
      return unwrapMutationData(response);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'athletes'] });
    },
  });
}

export function useCorrectAthlete() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, payload }: { id: string; payload: Record<string, any> }) => {
      const response = await apiClient.patch(`/admin/athletes/${id}/correct`, payload);
      return unwrapMutationData(response);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'athletes'] });
    },
  });
}

export function useRefereeCertifications(userId?: string) {
  return useQuery<RefereeCertification[]>({
    queryKey: ['referee-certifications', userId],
    queryFn: async () => {
      const response = await apiClient.get(`/referees/${userId}/certifications`);
      const payload = unwrapMutationData(response);
      if (!Array.isArray(payload)) {
        throw new Error('Invalid referee certifications payload from server.');
      }
      return payload as RefereeCertification[];
    },
    enabled: !!userId,
  });
}

export function useIssueRefereeCertification(_userId?: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ userId, payload }: { userId: string; payload: IssueCertificationPayload }) => {
      const response = await apiClient.post(`/referees/${userId}/certifications`, payload);
      return unwrapMutationData(response);
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ['referee-certifications', variables.userId] });
    },
  });
}

export function useRevokeRefereeCertification(userId?: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id }: { id: string; userId: string }) => {
      const response = await apiClient.patch(`/referees/certifications/${id}/revoke`);
      return unwrapMutationData(response);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['referee-certifications', userId] });
    },
  });
}
