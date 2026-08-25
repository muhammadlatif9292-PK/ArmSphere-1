import { useQuery } from '@tanstack/react-query';
import { apiClient, unwrapMutationData } from './apiClient';

export interface AuditEvent {
  id: string;
  eventId: string;
  actorId: string | null;
  entityType: string;
  entityId: string;
  action: string;
  payload: Record<string, any> | null;
  parentHash: string;
  eventHash: string;
  createdAt: string;
}

export interface LedgerVerification {
  isValid: boolean;
  tamperedEventId?: string;
  reason?: string;
  totalEventsVerified: number;
}

export function useAuditEvents() {
  return useQuery<AuditEvent[]>({
    queryKey: ['admin', 'audit', 'events'],
    queryFn: async () => {
      const response = await apiClient.get('/admin/audit/events');
      const payload = unwrapMutationData(response);
      if (!Array.isArray(payload)) {
        throw new Error('Invalid audit events payload from server.');
      }
      return payload as AuditEvent[];
    },
  });
}

export function useVerifyLedger() {
  return useQuery<LedgerVerification>({
    queryKey: ['admin', 'audit', 'verify'],
    queryFn: async () => {
      const response = await apiClient.get('/admin/audit/verify');
      const payload = unwrapMutationData(response);
      if (!payload || typeof payload !== 'object' || typeof payload.isValid !== 'boolean') {
        throw new Error('Invalid ledger verification payload from server.');
      }
      return payload as LedgerVerification;
    },
  });
}
