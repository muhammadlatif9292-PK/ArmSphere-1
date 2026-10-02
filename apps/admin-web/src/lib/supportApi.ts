import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient, unwrapMutationData } from './apiClient';
import { SupportTicket, SupportTicketMessage } from '../types';

export interface SupportTicketFilters {
  status?: string;
  category?: string;
  assignedAgentId?: string;
  myTicketsOnly?: boolean;
}

export function useSupportTickets(filters: SupportTicketFilters = {}) {
  return useQuery<SupportTicket[]>({
    queryKey: ['support', 'tickets', filters],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (filters.status && filters.status !== 'ALL') params.append('status', filters.status);
      if (filters.category && filters.category !== 'ALL') params.append('category', filters.category);
      if (filters.assignedAgentId) params.append('assignedAgentId', filters.assignedAgentId);
      if (filters.myTicketsOnly) params.append('myTicketsOnly', 'true');

      const url = `/support/tickets${params.toString() ? `?${params.toString()}` : ''}`;
      const response = await apiClient.get(url);
      const payload = unwrapMutationData(response);
      if (!Array.isArray(payload)) {
        throw new Error('Invalid tickets payload received from server.');
      }
      return payload as SupportTicket[];
    },
  });
}

export function useSupportTicket(ticketId: string | null) {
  return useQuery<SupportTicket>({
    queryKey: ['support', 'ticket', ticketId],
    queryFn: async () => {
      if (!ticketId) throw new Error('Ticket ID is required.');
      const response = await apiClient.get(`/support/tickets/${ticketId}`);
      return unwrapMutationData(response) as SupportTicket;
    },
    enabled: Boolean(ticketId),
  });
}

export function useAssignTicket() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ ticketId, agentId }: { ticketId: string; agentId: string | null }) => {
      const response = await apiClient.post(`/support/tickets/${ticketId}/assign`, { agentId });
      return unwrapMutationData(response);
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['support', 'tickets'] });
      queryClient.invalidateQueries({ queryKey: ['support', 'ticket', variables.ticketId] });
    },
  });
}

export function useUpdateTicketStatus() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({
      ticketId,
      status,
      resolutionNotes,
    }: {
      ticketId: string;
      status: string;
      resolutionNotes?: string;
    }) => {
      const response = await apiClient.patch(`/support/tickets/${ticketId}/status`, {
        status,
        resolutionNotes,
      });
      return unwrapMutationData(response);
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['support', 'tickets'] });
      queryClient.invalidateQueries({ queryKey: ['support', 'ticket', variables.ticketId] });
    },
  });
}

export function useAddTicketMessage() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({
      ticketId,
      message,
      isInternal,
    }: {
      ticketId: string;
      message: string;
      isInternal?: boolean;
    }) => {
      const response = await apiClient.post(`/support/tickets/${ticketId}/messages`, {
        message,
        isInternal,
      });
      return unwrapMutationData(response) as SupportTicketMessage;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['support', 'ticket', variables.ticketId] });
    },
  });
}
