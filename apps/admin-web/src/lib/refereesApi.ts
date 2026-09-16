import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient, unwrapMutationData } from './apiClient';
import {
  RefereeAdminView,
  AssignRefereeRegionPayload,
  UpdateRefereeLicensePayload,
  SuspendRefereePayload,
} from '../types';

export function useReferees() {
  return useQuery<RefereeAdminView[]>({
    queryKey: ['admin', 'referees'],
    queryFn: async () => {
      const response = await apiClient.get('/admin/referees');
      const payload = unwrapMutationData(response);
      if (!Array.isArray(payload)) {
        throw new Error('Invalid referees payload from server.');
      }
      return payload as RefereeAdminView[];
    },
  });
}

export function useAssignRefereeRegion() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, payload }: { id: string; payload: AssignRefereeRegionPayload }) => {
      const response = await apiClient.post(`/admin/referees/${id}/region`, payload);
      return unwrapMutationData(response);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'referees'] });
    },
  });
}

export function useUpdateRefereeLicense() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, payload }: { id: string; payload: UpdateRefereeLicensePayload }) => {
      const response = await apiClient.post(`/admin/referees/${id}/license`, payload);
      return unwrapMutationData(response);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'referees'] });
    },
  });
}

export function useSuspendReferee() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, payload }: { id: string; payload: SuspendRefereePayload }) => {
      const response = await apiClient.post(`/admin/referees/${id}/suspend`, payload);
      return unwrapMutationData(response);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'referees'] });
    },
  });
}
