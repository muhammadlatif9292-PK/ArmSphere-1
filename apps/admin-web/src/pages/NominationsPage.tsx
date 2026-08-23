import { useState, useMemo } from 'react';
import {
  Users,
  Search,
  XCircle,
  RefreshCw,
  MapPin,
  Loader2,
  PhoneCall,
  UserCheck,
  ClipboardList,
  AlertCircle
} from 'lucide-react';
import { useNominations, useUpdateNominationStatus } from '../lib/nominationsApi';
import { useAuth } from '../context/AuthContext';
import { UserRole } from '../types';

export default function NominationsPage() {
  const { user } = useAuth();

  // Search & Filters state
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [provinceFilter, setProvinceFilter] = useState('');

  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;

  // Query hook
  const {
    data: nominations = [],
    isLoading,
    isError,
    error,
    refetch
  } = useNominations();

  // Mutation hook
  const updateStatusMutation = useUpdateNominationStatus();
  const [activeActionNomId, setActiveActionNomId] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  // Check roles (SYSTEM_ADMIN, NATIONAL_DIRECTOR, PROVINCIAL_DIRECTOR can update status)
  const canManage = user && [
    UserRole.SYSTEM_ADMIN,
    UserRole.NATIONAL_DIRECTOR,
    UserRole.PROVINCIAL_DIRECTOR
  ].includes(user.role);

  // Provinces list for filtering
  const provincesList = useMemo(() => {
    const list = nominations.map(n => n.province).filter(Boolean);
    return Array.from(new Set(list)).sort();
  }, [nominations]);

  // Client-side filtering based on search query, status, and province selections
  const filteredNominations = useMemo(() => {
    return nominations.filter(n => {
      const matchesSearch = searchQuery === '' ||
        n.nomineeName.toLowerCase().includes(searchQuery.toLowerCase()) ||
        n.city.toLowerCase().includes(searchQuery.toLowerCase()) ||
        n.province.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (n.notes && n.notes.toLowerCase().includes(searchQuery.toLowerCase()));

      const matchesStatus = statusFilter === '' || n.status === statusFilter;
      const matchesProvince = provinceFilter === '' || n.province === provinceFilter;

      return matchesSearch && matchesStatus && matchesProvince;
    });
  }, [nominations, searchQuery, statusFilter, provinceFilter]);

  // Pagination slice
  const paginatedNominations = useMemo(() => {
    const startIndex = (currentPage - 1) * itemsPerPage;
    return filteredNominations.slice(startIndex, startIndex + itemsPerPage);
  }, [filteredNominations, currentPage]);

  const totalPages = Math.ceil(filteredNominations.length / itemsPerPage);

  const handleStatusChange = async (nominationId: string, newStatus: string) => {
    if (!canManage) return;
    setActiveActionNomId(nominationId);
    setActionError(null);
    try {
      await updateStatusMutation.mutateAsync({ id: nominationId, status: newStatus });
    } catch (err: any) {
      setActionError(err?.message || 'Failed to update status');
    } finally {
      setActiveActionNomId(null);
    }
  };

  // Stats cards computations
  const stats = useMemo(() => {
    const counts = { PENDING: 0, CONTACTED: 0, REGISTERED: 0, DECLINED: 0 };
    nominations.forEach(n => {
      if (counts[n.status] !== undefined) {
        counts[n.status]++;
      }
    });
    return counts;
  }, [nominations]);

  return (
    <div className="space-y-6" id="nominations-page-root">
      {/* Header section */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            <Users className="h-6 w-6 text-amber-500" />
            Talent Nominations
          </h1>
          <p className="mt-1 text-sm text-slate-400">
            Scouting directory and recruitment pipeline for promising armwrestling athletes.
          </p>
        </div>
        <button
          onClick={() => refetch()}
          disabled={isLoading}
          className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium bg-slate-800 text-slate-300 hover:text-white rounded-md transition-colors disabled:opacity-50 border border-slate-700"
          id="btn-refresh-nominations"
        >
          <RefreshCw className={`h-3.5 w-3.5 ${isLoading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      {/* Stats row */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-4 flex items-center gap-4">
          <div className="p-3 rounded-lg bg-yellow-500/10 text-yellow-500">
            <ClipboardList className="h-6 w-6" />
          </div>
          <div>
            <p className="text-xs font-medium text-slate-400 uppercase tracking-wider">Pending</p>
            <p className="text-2xl font-bold text-white mt-0.5">{stats.PENDING}</p>
          </div>
        </div>

        <div className="bg-slate-900 border border-slate-800 rounded-xl p-4 flex items-center gap-4">
          <div className="p-3 rounded-lg bg-blue-500/10 text-blue-500">
            <PhoneCall className="h-6 w-6" />
          </div>
          <div>
            <p className="text-xs font-medium text-slate-400 uppercase tracking-wider">Contacted</p>
            <p className="text-2xl font-bold text-white mt-0.5">{stats.CONTACTED}</p>
          </div>
        </div>

        <div className="bg-slate-900 border border-slate-800 rounded-xl p-4 flex items-center gap-4">
          <div className="p-3 rounded-lg bg-emerald-500/10 text-emerald-500">
            <UserCheck className="h-6 w-6" />
          </div>
          <div>
            <p className="text-xs font-medium text-slate-400 uppercase tracking-wider">Registered</p>
            <p className="text-2xl font-bold text-white mt-0.5">{stats.REGISTERED}</p>
          </div>
        </div>

        <div className="bg-slate-900 border border-slate-800 rounded-xl p-4 flex items-center gap-4">
          <div className="p-3 rounded-lg bg-rose-500/10 text-rose-500">
            <XCircle className="h-6 w-6" />
          </div>
          <div>
            <p className="text-xs font-medium text-slate-400 uppercase tracking-wider">Declined</p>
            <p className="text-2xl font-bold text-white mt-0.5">{stats.DECLINED}</p>
          </div>
        </div>
      </div>

      {actionError && (
        <div className="bg-rose-500/15 border border-rose-500/30 rounded-lg p-3 flex items-center gap-2 text-rose-400 text-sm">
          <AlertCircle className="h-4 w-4" />
          {actionError}
        </div>
      )}

      {/* Filters and search panel */}
      <div className="bg-slate-900 border border-slate-800 rounded-xl p-4 space-y-4">
        <div className="flex flex-col md:flex-row gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
            <input
              type="text"
              placeholder="Search by nominee name, city, province..."
              value={searchQuery}
              onChange={(e) => {
                setSearchQuery(e.target.value);
                setCurrentPage(1);
              }}
              className="w-full pl-9 pr-4 py-2 bg-slate-950 border border-slate-800 rounded-lg text-sm text-white placeholder-slate-500 focus:outline-none focus:border-amber-500"
              id="input-search-nominations"
            />
          </div>

          <div className="w-full md:w-48">
            <select
              value={statusFilter}
              onChange={(e) => {
                setStatusFilter(e.target.value);
                setCurrentPage(1);
              }}
              className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-lg text-sm text-white focus:outline-none focus:border-amber-500"
              id="select-filter-status"
            >
              <option value="">All Statuses</option>
              <option value="PENDING">Pending</option>
              <option value="CONTACTED">Contacted</option>
              <option value="REGISTERED">Registered</option>
              <option value="DECLINED">Declined</option>
            </select>
          </div>

          <div className="w-full md:w-48">
            <select
              value={provinceFilter}
              onChange={(e) => {
                setProvinceFilter(e.target.value);
                setCurrentPage(1);
              }}
              className="w-full px-3 py-2 bg-slate-950 border border-slate-800 rounded-lg text-sm text-white focus:outline-none focus:border-amber-500"
              id="select-filter-province"
            >
              <option value="">All Provinces</option>
              {provincesList.map(prov => (
                <option key={prov} value={prov}>{prov}</option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Table Listing */}
      <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
        {isLoading ? (
          <div className="flex flex-col items-center justify-center py-12 text-slate-400 gap-2">
            <Loader2 className="h-8 w-8 animate-spin text-amber-500" />
            <span>Loading nominations data...</span>
          </div>
        ) : isError ? (
          <div className="flex flex-col items-center justify-center py-12 text-slate-400 gap-2">
            <AlertCircle className="h-8 w-8 text-rose-500" />
            <span className="text-white font-medium">Failed to load nominations</span>
            <span className="text-sm text-slate-500">{error instanceof Error ? error.message : 'Unknown error'}</span>
            <button
              onClick={() => refetch()}
              className="mt-4 px-4 py-2 bg-slate-800 text-white rounded-lg text-sm hover:bg-slate-700"
            >
              Retry
            </button>
          </div>
        ) : filteredNominations.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-12 text-slate-400 gap-2">
            <ClipboardList className="h-8 w-8 text-slate-600" />
            <span className="text-white font-medium">No nominations found</span>
            <p className="text-sm text-slate-500">Try adjusting your filters or search query.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-300">
              <thead className="bg-slate-950/60 text-xs font-semibold text-slate-400 uppercase tracking-wider border-b border-slate-800/80">
                <tr>
                  <th className="px-6 py-3.5">Nominee</th>
                  <th className="px-6 py-3.5">Location</th>
                  <th className="px-6 py-3.5">Contact Info</th>
                  <th className="px-6 py-3.5">Notes</th>
                  <th className="px-6 py-3.5">Status</th>
                  <th className="px-6 py-3.5 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-850">
                {paginatedNominations.map((nom) => {
                  const isUpdating = activeActionNomId === nom.id;

                  return (
                    <tr key={nom.id} className="hover:bg-slate-950/20 transition-colors">
                      <td className="px-6 py-4">
                        <div className="font-semibold text-white">{nom.nomineeName}</div>
                        <div className="text-xs text-slate-500 mt-0.5">
                          Submitted {new Date(nom.createdAt).toLocaleDateString()}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-1">
                          <MapPin className="h-3.5 w-3.5 text-slate-500" />
                          <span>{nom.city}, {nom.province}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <span className="text-slate-300 font-mono text-xs">
                          {nom.nomineeContact || 'None provided'}
                        </span>
                      </td>
                      <td className="px-6 py-4 max-w-xs">
                        <p className="truncate text-slate-400 text-xs" title={nom.notes || ''}>
                          {nom.notes || '—'}
                        </p>
                      </td>
                      <td className="px-6 py-4">
                        {nom.status === 'PENDING' && (
                          <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-yellow-500/10 text-yellow-500 border border-yellow-500/20">
                            Pending
                          </span>
                        )}
                        {nom.status === 'CONTACTED' && (
                          <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-500/10 text-blue-500 border border-blue-500/20">
                            Contacted
                          </span>
                        )}
                        {nom.status === 'REGISTERED' && (
                          <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-emerald-500/10 text-emerald-500 border border-emerald-500/20">
                            Registered
                          </span>
                        )}
                        {nom.status === 'DECLINED' && (
                          <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-rose-500/10 text-rose-500 border border-rose-500/20">
                            Declined
                          </span>
                        )}
                      </td>
                      <td className="px-6 py-4 text-right">
                        {canManage ? (
                          <div className="flex items-center justify-end gap-1.5">
                            {nom.status === 'PENDING' && (
                              <button
                                onClick={() => handleStatusChange(nom.id, 'CONTACTED')}
                                disabled={isUpdating}
                                className="inline-flex items-center px-2.5 py-1 text-xs font-semibold rounded bg-blue-500 text-slate-900 hover:bg-blue-400 transition-colors disabled:opacity-50"
                              >
                                {isUpdating ? '...' : 'Mark Contacted'}
                              </button>
                            )}
                            {nom.status === 'CONTACTED' && (
                              <>
                                <button
                                  onClick={() => handleStatusChange(nom.id, 'REGISTERED')}
                                  disabled={isUpdating}
                                  className="inline-flex items-center px-2.5 py-1 text-xs font-semibold rounded bg-emerald-500 text-slate-900 hover:bg-emerald-400 transition-colors disabled:opacity-50"
                                >
                                  Registered
                                </button>
                                <button
                                  onClick={() => handleStatusChange(nom.id, 'DECLINED')}
                                  disabled={isUpdating}
                                  className="inline-flex items-center px-2.5 py-1 text-xs font-semibold rounded bg-rose-500 text-white hover:bg-rose-450 transition-colors disabled:opacity-50"
                                >
                                  Decline
                                </button>
                              </>
                            )}
                            {['REGISTERED', 'DECLINED'].includes(nom.status) && (
                              <span className="text-xs text-slate-500">Pipeline Finished</span>
                            )}
                          </div>
                        ) : (
                          <span className="text-xs text-slate-500">No Permission</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}

        {/* Pagination bar */}
        {totalPages > 1 && (
          <div className="bg-slate-950/40 px-6 py-3 flex items-center justify-between border-t border-slate-800">
            <div className="text-xs text-slate-400">
              Showing page {currentPage} of {totalPages}
            </div>
            <div className="flex items-center gap-2">
              <button
                disabled={currentPage === 1}
                onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                className="px-2.5 py-1 text-xs bg-slate-800 hover:bg-slate-700 text-white rounded transition-colors disabled:opacity-40"
              >
                Previous
              </button>
              <button
                disabled={currentPage === totalPages}
                onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
                className="px-2.5 py-1 text-xs bg-slate-800 hover:bg-slate-700 text-white rounded transition-colors disabled:opacity-40"
              >
                Next
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
