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


