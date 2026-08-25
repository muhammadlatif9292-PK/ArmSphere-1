import axios from 'axios';

const getInitialBaseUrl = () => {
  // Most admin/governance/venue/etc. routes are mounted at API root, not under /api/v1.
  // Only a few routers (auth, matches, analytics, notifications) are additionally
  // double-mounted under /api/v1 for REST-convention compatibility. Default to root.
  if (typeof window !== 'undefined' && window.location) {
    return window.location.origin;
  }
  return '';
};

const API_BASE_URL = (import.meta as any).env?.VITE_API_BASE_URL || getInitialBaseUrl();

let inMemoryToken: string | null = null;

export function setAuthToken(token: string | null) {
  inMemoryToken = token;
}

export function getAuthToken(): string | null {
  return inMemoryToken;
}

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 8000,
});

apiClient.interceptors.request.use(
  (config) => {
    if (inMemoryToken) {
      config.headers.Authorization = `Bearer ${inMemoryToken}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Surface real server failure details instead of swallowing them.
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    const detail = error?.response?.data?.detail || error?.response?.data?.message;
    if (detail) {
      error.message = Array.isArray(detail) ? detail.map((d: any) => d?.message || String(d)).join('; ') : String(detail);
    }
    return Promise.reject(error);
  }
);

// Unwrap a { success, data } envelope and reject business-level failures.
export function unwrapMutationData(response: { data: any }): any {
  const payload = response.data;
  if (payload && typeof payload === 'object' && payload.success === false) {
    throw new Error(payload.detail || payload.message || 'Request failed.');
  }
  return payload && typeof payload === 'object' && 'data' in payload ? payload.data : payload;
}


