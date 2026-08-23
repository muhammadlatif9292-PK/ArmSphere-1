import React, { createContext, useContext, useState, useEffect } from 'react';
import { apiClient, setAuthToken } from '../lib/apiClient';
import { User, UserRole, ADMIN_ROLES } from '../types';

interface AuthContextType {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<User>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

// Safe localStorage helpers for sandboxed iframe environments
function getSafeStorageItem(key: string): string | null {
  try {
    return localStorage.getItem(key);
  } catch {
    return null;
  }
}

function setSafeStorageItem(key: string, value: string): void {
  try {
    localStorage.setItem(key, value);
  } catch {
    // Ignored in sandboxed storage environments
  }
}

function removeSafeStorageItem(key: string): void {
  try {
    localStorage.removeItem(key);
  } catch {
    // Ignored in sandboxed storage environments
  }
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  // Initialize and attempt to recover session via cookie-based refresh token or cached local session
  useEffect(() => {
    async function initAuth() {
      try {
        const cachedUserStr = getSafeStorageItem('armsphere_admin_user');
        const cachedToken = getSafeStorageItem('armsphere_admin_token');
        if (cachedUserStr && cachedToken) {
          try {
            const parsed = JSON.parse(cachedUserStr);
            setUser(parsed);
            setToken(cachedToken);
            setAuthToken(cachedToken);
          } catch {
            removeSafeStorageItem('armsphere_admin_user');
            removeSafeStorageItem('armsphere_admin_token');
          }
        }

        // Attempt to call refresh token endpoint
        const res = await apiClient.post('/auth/refresh', {}, { withCredentials: true });
        if (res.data && res.data.success && res.data.data) {
          const { accessToken, user: loggedUser } = res.data.data;
          
          if (ADMIN_ROLES.includes(loggedUser.role as UserRole)) {
            setToken(accessToken);
            setAuthToken(accessToken);
            setUser(loggedUser);
            setSafeStorageItem('armsphere_admin_user', JSON.stringify(loggedUser));
            setSafeStorageItem('armsphere_admin_token', accessToken);
          } else {
            setAuthToken(null);
            removeSafeStorageItem('armsphere_admin_user');
            removeSafeStorageItem('armsphere_admin_token');
          }
        }
      } catch (err) {
        // Ignored, session not recoverable via API
      } finally {
        setIsLoading(false);
      }
    }

    initAuth();
  }, []);

  const login = async (email: string, password: string): Promise<User> => {
    const response = await apiClient.post('/auth/login', { email, password }, { withCredentials: true });
    
    if (response.data && response.data.success && response.data.data) {
      const { user: loggedUser, accessToken } = response.data.data;

      if (!ADMIN_ROLES.includes(loggedUser.role as UserRole)) {
        throw new Error(`Access denied. Role privilege required. Current: ${loggedUser.role}`);
      }

      setToken(accessToken);
      setAuthToken(accessToken);
      setUser(loggedUser);
      setSafeStorageItem('armsphere_admin_user', JSON.stringify(loggedUser));
      setSafeStorageItem('armsphere_admin_token', accessToken);
      return loggedUser;
    }
    throw new Error('Authentication failed');
  };

  const logout = async () => {
    try {
      await apiClient.post('/auth/logout', {}, { withCredentials: true });
    } catch (err) {
      // Ignore logout API failures and clear local memory
    } finally {
      setToken(null);
      setAuthToken(null);
      setUser(null);
      removeSafeStorageItem('armsphere_admin_user');
      removeSafeStorageItem('armsphere_admin_token');
    }
  };

  return (
    <AuthContext.Provider value={{ user, token, isLoading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
