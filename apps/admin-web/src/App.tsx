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
import ModerationQueuePage from './pages/ModerationQueuePage';
import VenuesPage from './pages/VenuesPage';
import NominationsPage from './pages/NominationsPage';

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
      retry: 1,
    },
  },
});

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, isLoading } = useAuth();
  const location = useLocation();

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-[#0B0F19]">
        <div className="w-10 h-10 border-4 border-amber-500 border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return <>{children}</>;
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

              {/* Protected Shell Routes */}
              <Route
                path="/"
                element={
                  <ProtectedRoute>
                    <AdminShell>
                      <DashboardPage />
                    </AdminShell>
                  </ProtectedRoute>
                }
              />
              <Route
                path="/analytics"
                element={
                  <ProtectedRoute>
                    <AdminShell>
                      <AnalyticsPage />
                    </AdminShell>
                  </ProtectedRoute>
                }
              />
              <Route
                path="/championships"
                element={
                  <ProtectedRoute>
                    <AdminShell>
                      <ChampionshipsPage />
                    </AdminShell>
                  </ProtectedRoute>
                }
              />
              <Route
                path="/governance"
                element={
                  <ProtectedRoute>
                    <AdminShell>
                      <GovernancePage />
                    </AdminShell>
                  </ProtectedRoute>
                }
              />
              <Route
                path="/athletes"
                element={
                  <ProtectedRoute>
                    <AdminShell>
                      <AthletesPage />
                    </AdminShell>
                  </ProtectedRoute>
                }
              />
              <Route
                path="/registrations"
                element={
                  <ProtectedRoute>
                    <AdminShell>
                      <AthletesPage />
                    </AdminShell>
                  </ProtectedRoute>
                }
              />
              <Route
                path="/moderation"
                element={
                  <ProtectedRoute>
                    <AdminShell>
                      <ModerationQueuePage />
                    </AdminShell>
                  </ProtectedRoute>
                }
              />
              <Route
                path="/venues"
                element={
                  <ProtectedRoute>
                    <AdminShell>
                      <VenuesPage />
                    </AdminShell>
                  </ProtectedRoute>
                }
              />
              <Route
                path="/nominations"
                element={
                  <ProtectedRoute>
                    <AdminShell>
                      <NominationsPage />
                    </AdminShell>
                  </ProtectedRoute>
                }
              />
              <Route
                path="/records"
                element={
                  <ProtectedRoute>
                    <AdminShell>
                      <GovernancePage />
                    </AdminShell>
                  </ProtectedRoute>
                }
              />
              <Route
                path="/verification"
                element={
                  <ProtectedRoute>
                    <AdminShell>
                      <AthletesPage />
                    </AdminShell>
                  </ProtectedRoute>
                }
              />
              <Route
                path="/audit"
                element={
                  <ProtectedRoute>
                    <AdminShell>
                      <GovernancePage />
                    </AdminShell>
                  </ProtectedRoute>
                }
              />
              <Route
                path="/platform-health"
                element={
                  <ProtectedRoute>
                    <AdminShell>
                      <AnalyticsPage />
                    </AdminShell>
                  </ProtectedRoute>
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
