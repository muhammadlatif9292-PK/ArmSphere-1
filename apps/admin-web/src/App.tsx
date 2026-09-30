import React, { Component, ErrorInfo, ReactNode } from 'react';
import { BrowserRouter, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider, useAuth } from './context/AuthContext';
import AdminShell from './layout/AdminShell';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import AnalyticsPage from './pages/AnalyticsPage';
import ChampionshipsPage from './pages/ChampionshipsPage';
import GovernancePage from './pages/GovernancePage';
import AthletesPage from './pages/AthletesPage';
import RefereesPage from './pages/RefereesPage';
import ModerationQueuePage from './pages/ModerationQueuePage';
import VenuesPage from './pages/VenuesPage';
import NominationsPage from './pages/NominationsPage';
import AuditPage from './pages/AuditPage';
import ForbiddenPage from './pages/ForbiddenPage';
import { canAccessRoute } from './lib/authorizationPolicy';

interface ErrorBoundaryProps {
  children: ReactNode;
}

interface ErrorBoundaryState {
  hasError: boolean;
  error: Error | null;
}

class AppErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  public state: ErrorBoundaryState = {
    hasError: false,
    error: null,
  };

  public static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error };
  }

  public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('Uncaught error in ArmSphere Admin Web:', error, errorInfo);
  }

  public render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen bg-[#070A11] text-slate-100 flex items-center justify-center p-6 font-sans">
          <div className="max-w-md w-full bg-[#0F172A] border border-slate-800 rounded-2xl p-8 text-center space-y-4 shadow-2xl">
            <div className="w-12 h-12 bg-amber-500/10 text-amber-400 border border-amber-500/20 rounded-full flex items-center justify-center mx-auto text-xl font-bold">
              🛡️
            </div>
            <h2 className="text-xl font-display font-bold text-slate-100">ArmSphere Console Recovery</h2>
            <p className="text-xs text-slate-400 leading-relaxed font-mono">
              An unexpected execution anomaly was contained safely. The application state remains protected.
            </p>
            {this.state.error?.message && (
              <div className="p-3 bg-[#070A11] border border-slate-800 rounded-lg text-left text-[11px] font-mono text-red-400 overflow-x-auto">
                {this.state.error.message}
              </div>
            )}
            <button
              onClick={() => {
                this.setState({ hasError: false, error: null });
                window.location.href = '/';
              }}
              className="w-full py-2.5 bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold text-xs rounded-lg transition-colors font-mono uppercase"
            >
              Restart Console Operations
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: (failureCount, error: any) => {
        // Never retry 401 or 403 authorization failures
        const status = error?.response?.status;
        if (status === 401 || status === 403) return false;
        return failureCount < 1;
      },
    },
  },
});

interface RoleGuardedRouteProps {
  path: string;
  children: React.ReactNode;
}

export function RoleGuardedRoute({ path, children }: RoleGuardedRouteProps) {
  const { user, isLoading } = useAuth();
  const location = useLocation();

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-[#070A11]">
        <div className="w-10 h-10 border-4 border-amber-500 border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  const access = canAccessRoute(user, path);
  if (!access.allowed) {
    return (
      <AdminShell>
        <ForbiddenPage
          requiredRoles={access.requiredRoles}
          currentRole={access.userRole}
        />
      </AdminShell>
    );
  }

  return <AdminShell>{children}</AdminShell>;
}

export default function App() {
  return (
    <AppErrorBoundary>
      <QueryClientProvider client={queryClient}>
        <AuthProvider>
          <BrowserRouter>
            <Routes>
              {/* Public Auth Route */}
              <Route path="/login" element={<LoginPage />} />

              {/* Protected Shell Routes with Central Route-Level RBAC Enforcement */}
              <Route
                path="/"
                element={
                  <RoleGuardedRoute path="/">
                    <DashboardPage />
                  </RoleGuardedRoute>
                }
              />
              <Route
                path="/analytics"
                element={
                  <RoleGuardedRoute path="/analytics">
                    <AnalyticsPage />
                  </RoleGuardedRoute>
                }
              />
              <Route
                path="/championships"
                element={
                  <RoleGuardedRoute path="/championships">
                    <ChampionshipsPage />
                  </RoleGuardedRoute>
                }
              />
              <Route
                path="/governance"
                element={
                  <RoleGuardedRoute path="/governance">
                    <GovernancePage />
                  </RoleGuardedRoute>
                }
              />
              <Route
                path="/athletes"
                element={
                  <RoleGuardedRoute path="/athletes">
                    <AthletesPage />
                  </RoleGuardedRoute>
                }
              />
              <Route
                path="/referees"
                element={
                  <RoleGuardedRoute path="/referees">
                    <RefereesPage />
                  </RoleGuardedRoute>
                }
              />
              <Route
                path="/moderation"
                element={
                  <RoleGuardedRoute path="/moderation">
                    <ModerationQueuePage />
                  </RoleGuardedRoute>
                }
              />
              <Route
                path="/venues"
                element={
                  <RoleGuardedRoute path="/venues">
                    <VenuesPage />
                  </RoleGuardedRoute>
                }
              />
              <Route
                path="/nominations"
                element={
                  <RoleGuardedRoute path="/nominations">
                    <NominationsPage />
                  </RoleGuardedRoute>
                }
              />
              <Route
                path="/audit"
                element={
                  <RoleGuardedRoute path="/audit">
                    <AuditPage />
                  </RoleGuardedRoute>
                }
              />

              {/* Fallback Catch All */}
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </BrowserRouter>
        </AuthProvider>
      </QueryClientProvider>
    </AppErrorBoundary>
  );
}
