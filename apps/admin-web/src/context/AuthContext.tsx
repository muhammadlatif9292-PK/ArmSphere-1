import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { apiClient, setAuthToken, onUnauthorized } from '../lib/apiClient';
import { User, UserRole, ADMIN_ROLES } from '../types';
import { canSwitchToRole, getEffectiveRole, getUserJurisdiction } from '../lib/authorizationPolicy';

export interface AuthContextType {
  user: User | null;
  activeRole: UserRole | null;
  jurisdiction: string | null;
  token: string | null;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<User>;
  logout: () => Promise<void>;
  switchActiveRole: (newRole: UserRole) => boolean;
}

export const AuthContext = createContext<AuthContextType | undefined>(undefined);

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

  const logout = useCallback(async () => {
    try {
      await apiClient.post('/auth/logout', {}, { withCredentials: true });
    } catch {
      // Ignore logout API failures and clear local memory
    } finally {
      setToken(null);
      setAuthToken(null);
      setUser(null);
      removeSafeStorageItem('armsphere_admin_user');
      removeSafeStorageItem('armsphere_admin_token');
      removeSafeStorageItem('armsphere_admin_active_role');
    }
  }, []);

  // Listen for 401 unauthorized signals from apiClient
  useEffect(() => {
    onUnauthorized(() => {
      logout();
    });
    return () => {
      onUnauthorized(null);
    };
  }, [logout]);

  // Initialize and attempt to recover session via cookie-based refresh token or cached local session
  useEffect(() => {
    async function initAuth() {
      try {
        const cachedUserStr = getSafeStorageItem('armsphere_admin_user');
        const cachedToken = getSafeStorageItem('armsphere_admin_token');
        const cachedActiveRole = getSafeStorageItem('armsphere_admin_active_role') as UserRole | null;

        if (cachedUserStr && cachedToken) {
          try {
            const parsed = JSON.parse(cachedUserStr) as User;
            const effectiveRole = cachedActiveRole && canSwitchToRole(parsed, cachedActiveRole)
              ? cachedActiveRole
              : parsed.role;
            setUser({ ...parsed, activeRole: effectiveRole });
            setToken(cachedToken);
            setAuthToken(cachedToken);
          } catch {
            removeSafeStorageItem('armsphere_admin_user');
            removeSafeStorageItem('armsphere_admin_token');
            removeSafeStorageItem('armsphere_admin_active_role');
          }
        }

        // Attempt to call refresh token endpoint
        const res = await apiClient.post('/auth/refresh', {}, { withCredentials: true });
        if (res.data && res.data.success && res.data.data) {
          const { accessToken, user: loggedUser } = res.data.data;

          const userRoles: UserRole[] = [];
          if (loggedUser.role) userRoles.push(loggedUser.role as UserRole);
          if (Array.isArray(loggedUser.verifiedRoles)) {
            userRoles.push(...(loggedUser.verifiedRoles as UserRole[]));
          }

          const hasAdminPrivilege = userRoles.some((r) => ADMIN_ROLES.includes(r));

          if (hasAdminPrivilege) {
            const savedActiveRole = getSafeStorageItem('armsphere_admin_active_role') as UserRole | null;
            const validActive = savedActiveRole && canSwitchToRole(loggedUser, savedActiveRole)
              ? savedActiveRole
              : (ADMIN_ROLES.find((r) => userRoles.includes(r)) || loggedUser.role);

            const enrichedUser: User = {
              ...loggedUser,
              activeRole: validActive,
            };

            setToken(accessToken);
            setAuthToken(accessToken);
            setUser(enrichedUser);
            setSafeStorageItem('armsphere_admin_user', JSON.stringify(loggedUser));
            setSafeStorageItem('armsphere_admin_token', accessToken);
            setSafeStorageItem('armsphere_admin_active_role', validActive);
          } else {
            setAuthToken(null);
            removeSafeStorageItem('armsphere_admin_user');
            removeSafeStorageItem('armsphere_admin_token');
            removeSafeStorageItem('armsphere_admin_active_role');
          }
        }
      } catch {
        // Session not recoverable via API
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

      const userRoles: UserRole[] = [];
      if (loggedUser.role) userRoles.push(loggedUser.role as UserRole);
      if (Array.isArray(loggedUser.verifiedRoles)) {
        userRoles.push(...(loggedUser.verifiedRoles as UserRole[]));
      }

      const hasAdminPrivilege = userRoles.some((r) => ADMIN_ROLES.includes(r));
      if (!hasAdminPrivilege) {
        throw new Error(`Access denied. Role privilege required. Current: ${loggedUser.role}`);
      }

      const activeRole = ADMIN_ROLES.find((r) => userRoles.includes(r)) || (loggedUser.role as UserRole);
      const enrichedUser: User = {
        ...loggedUser,
        activeRole,
      };

      setToken(accessToken);
      setAuthToken(accessToken);
      setUser(enrichedUser);
      setSafeStorageItem('armsphere_admin_user', JSON.stringify(loggedUser));
      setSafeStorageItem('armsphere_admin_token', accessToken);
      setSafeStorageItem('armsphere_admin_active_role', activeRole);
      return enrichedUser;
    }
    throw new Error('Authentication failed');
  };

  const switchActiveRole = (newRole: UserRole): boolean => {
    if (!user) return false;
    if (!canSwitchToRole(user, newRole)) return false;

    const updatedUser: User = {
      ...user,
      activeRole: newRole,
    };
    setUser(updatedUser);
    setSafeStorageItem('armsphere_admin_active_role', newRole);
    return true;
  };

  const activeRole = getEffectiveRole(user);
  const jurisdiction = getUserJurisdiction(user);

  return (
    <AuthContext.Provider
      value={{
        user,
        activeRole,
        jurisdiction,
        token,
        isLoading,
        login,
        logout,
        switchActiveRole,
      }}
    >
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
