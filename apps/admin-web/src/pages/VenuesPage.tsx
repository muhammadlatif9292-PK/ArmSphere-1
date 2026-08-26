import React, { useState, useMemo } from 'react';
import {
  Building2,
  Search,
  CheckCircle,
  ShieldCheck,
  RefreshCw,
  MapPin,
  Loader2,
  Check,
  Info,
  PhoneCall
} from 'lucide-react';
import { useVenues, useVerifyVenue } from '../lib/venuesApi';
import { useAuth } from '../context/AuthContext';
import { UserRole } from '../types';
import { LoadingCard, ErrorPanel, EmptyState, ErrorBanner } from '../components/ui';

export default function VenuesPage() {
  const { user } = useAuth();

  // Search & Filters state
  const [searchQuery, setSearchQuery] = useState('');
  const [provinceFilter, setProvinceFilter] = useState('');
  const [cityFilter, setCityFilter] = useState('');

  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;

  // Query hook
  const {
    data: venues = [],
    isLoading,
    isError,
    error,
    refetch
  } = useVenues();

  // Verification Mutation
  const verifyMutation = useVerifyVenue();
  const [activeVerifyVenueId, setActiveVerifyVenueId] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  // Check roles (SYSTEM_ADMIN, NATIONAL_DIRECTOR, PROVINCIAL_DIRECTOR can verify)
  const canVerify = user && [
    UserRole.SYSTEM_ADMIN,
    UserRole.NATIONAL_DIRECTOR,
    UserRole.PROVINCIAL_DIRECTOR
  ].includes(user.role);

  // Extract distinct provinces and cities for filter dropdowns dynamically
  const provincesList = useMemo(() => {
    const list = venues.map(v => v.province).filter(Boolean);
    return Array.from(new Set(list)).sort();
  }, [venues]);

  const citiesList = useMemo(() => {
    const list = venues.map(v => v.city).filter(Boolean);
    return Array.from(new Set(list)).sort();
  }, [venues]);

  // Client-side filtering based on search query and dropdown selections
  const filteredVenues = useMemo(() => {
    return venues.filter(v => {
      const matchesSearch = searchQuery === '' ||
        v.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        v.address.toLowerCase().includes(searchQuery.toLowerCase()) ||
        v.city.toLowerCase().includes(searchQuery.toLowerCase()) ||
        v.province.toLowerCase().includes(searchQuery.toLowerCase());

      const matchesProvince = provinceFilter === '' || v.province === provinceFilter;
      const matchesCity = cityFilter === '' || v.city === cityFilter;

      return matchesSearch && matchesProvince && matchesCity;
    });
  }, [venues, searchQuery, provinceFilter, cityFilter]);

  // Client-side pagination slice
  const paginatedVenues = useMemo(() => {
    const startIndex = (currentPage - 1) * itemsPerPage;
    return filteredVenues.slice(startIndex, startIndex + itemsPerPage);
  }, [filteredVenues, currentPage]);

  const totalPages = Math.ceil(filteredVenues.length / itemsPerPage);

  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSearchQuery(e.target.value);
    setCurrentPage(1);
  };

  const handleProvinceChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setProvinceFilter(e.target.value);
    setCurrentPage(1);
  };

  const handleCityChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    setCityFilter(e.target.value);
    setCurrentPage(1);
  };

  // Perform verification action
  const handleVerify = async (venueId: string) => {
    try {
      setActionError(null);
      setActiveVerifyVenueId(venueId);
      await verifyMutation.mutateAsync(venueId);
    } catch (err: any) {
      setActionError(err.message || 'Failed to verify venue partner.');
    } finally {
      setActiveVerifyVenueId(null);
    }
  };

  // Stats calculation
  const totalCount = venues.length;
  const verifiedCount = venues.filter(v => v.isVerified).length;
  const unverifiedCount = totalCount - verifiedCount;

  return (
    <div className="space-y-6" id="venues-page-container">
      {/* Page Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between space-y-4 md:space-y-0">
        <div>
          <h1 className="text-2xl md:text-3xl font-display font-bold text-slate-100 tracking-tight flex items-center gap-3">
            <Building2 className="h-7 w-7 md:h-8 md:w-8 text-teal-400" />
            Venue Partners
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Directory of official gyms, training clubs, and venues. Approve official venue badges.
          </p>
        </div>
        <button
          onClick={() => refetch()}
          disabled={isLoading}
          className="inline-flex items-center gap-2 bg-brand-panel border border-slate-700 rounded-lg px-4 py-2 text-sm font-medium text-slate-300 hover:bg-brand-raised hover:text-slate-100 transition-colors cursor-pointer disabled:opacity-50"
        >
          <RefreshCw className={`h-4 w-4 ${isLoading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 md:gap-6">
        <div className="bg-brand-panel p-5 md:p-6 rounded-xl border border-slate-800 flex items-center gap-4">
          <div className="p-3 bg-blue-500/10 rounded-lg text-blue-400">
            <Building2 className="h-6 w-6" />
          </div>
          <div>
            <p className="text-sm text-slate-500 font-medium">Total Partners</p>
            <p className="text-2xl font-bold text-slate-100">{totalCount}</p>
          </div>
        </div>
        <div className="bg-brand-panel p-5 md:p-6 rounded-xl border border-slate-800 flex items-center gap-4">
          <div className="p-3 bg-emerald-500/10 rounded-lg text-emerald-400">
            <CheckCircle className="h-6 w-6" />
          </div>
          <div>
            <p className="text-sm text-slate-500 font-medium">Verified Official Gyms</p>
            <p className="text-2xl font-bold text-slate-100">{verifiedCount}</p>
          </div>
        </div>
        <div className="bg-brand-panel p-5 md:p-6 rounded-xl border border-slate-800 flex items-center gap-4">
          <div className="p-3 bg-amber-500/10 rounded-lg text-amber-400">
            <Info className="h-6 w-6" />
          </div>
          <div>
            <p className="text-sm text-slate-500 font-medium">Pending Verification</p>
            <p className="text-2xl font-bold text-slate-100">{unverifiedCount}</p>
          </div>
        </div>
      </div>

      {/* Action Error Banner */}
      <ErrorBanner message={actionError ?? ''} />

      {/* Search and Filters panel */}
      <div className="bg-brand-panel p-4 rounded-xl border border-slate-800 space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Search bar */}
          <div className="relative">
            <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-500" />
            <input
              type="text"
              placeholder="Search by gym name or address..."
              value={searchQuery}
              onChange={handleSearchChange}
              className="w-full bg-slate-900 border border-slate-800 rounded-lg pl-9 pr-4 py-2 text-sm text-slate-200 placeholder-slate-500 focus:outline-hidden focus:border-amber-500/60 focus:ring-1 focus:ring-amber-500/40"
            />
          </div>

          {/* Province selector */}
          <select
            value={provinceFilter}
            onChange={handleProvinceChange}
            className="bg-slate-900 border border-slate-800 rounded-lg px-3 py-2 text-sm text-slate-200 focus:outline-hidden focus:border-amber-500/60 focus:ring-1 focus:ring-amber-500/40"
          >
            <option value="">All Provinces</option>
            {provincesList.map(prov => (
              <option key={prov} value={prov}>{prov}</option>
            ))}
          </select>

          {/* City selector */}
          <select
            value={cityFilter}
            onChange={handleCityChange}
            className="bg-slate-900 border border-slate-800 rounded-lg px-3 py-2 text-sm text-slate-200 focus:outline-hidden focus:border-amber-500/60 focus:ring-1 focus:ring-amber-500/40"
          >
            <option value="">All Cities</option>
            {citiesList.map(city => (
              <option key={city} value={city}>{city}</option>
            ))}
          </select>
        </div>
      </div>

      {/* Venues Table Card */}
      <div className="bg-brand-panel rounded-xl border border-slate-800 overflow-hidden">
        {isLoading ? (
          <LoadingCard label="Loading venue directory..." />
        ) : isError ? (
          <ErrorPanel
            title="Failed to load venues"
            message={error?.message || 'Unknown network error.'}
            onRetry={() => refetch()}
            retryLabel="Retry Fetch"
          />
        ) : filteredVenues.length === 0 ? (
          <EmptyState
            icon={Building2}
            title="No venues found"
            subtitle="Try resetting filters or searching for something else."
          />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-900/60 border-b border-slate-800 text-xs font-semibold text-slate-400 uppercase tracking-wider">
                  <th className="px-6 py-4">Logo & Name</th>
                  <th className="px-6 py-4">Location</th>
                  <th className="px-6 py-4">Contact Info</th>
                  <th className="px-6 py-4">Verified Gym Partner</th>
                  <th className="px-6 py-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800 text-sm">
                {paginatedVenues.map((venue) => (
                  <tr key={venue.id} className="hover:bg-brand-raised/50 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-4">
                        <div className="h-10 w-10 rounded-lg bg-brand-raised border border-slate-700 flex items-center justify-center overflow-hidden shrink-0">
                          {venue.logoUrl ? (
                            <img src={venue.logoUrl} alt={venue.name} className="h-full w-full object-cover" />
                          ) : (
                            <Building2 className="h-5 w-5 text-slate-500" />
                          )}
                        </div>
                        <div>
                          <p className="font-semibold text-slate-100">{venue.name}</p>
                          {venue.description && (
                            <p className="text-xs text-slate-500 max-w-sm truncate mt-0.5">{venue.description}</p>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-start gap-1 text-slate-400">
                        <MapPin className="h-4 w-4 text-slate-500 shrink-0 mt-0.5" />
                        <div>
                          <p className="text-slate-200">{venue.address}</p>
                          <p className="text-xs text-slate-500">{venue.city}, {venue.province}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      {venue.contactInfo ? (
                        <div className="flex items-center gap-1.5 text-slate-300">
                          <PhoneCall className="h-3.5 w-3.5 text-slate-500" />
                          <span>{venue.contactInfo}</span>
                        </div>
                      ) : (
                        <span className="text-slate-600 font-mono text-xs">--</span>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      {venue.isVerified ? (
                        <span className="inline-flex items-center gap-1.5 bg-emerald-500/10 text-emerald-400 px-2.5 py-1 rounded-full text-xs font-semibold border border-emerald-500/20">
                          <ShieldCheck className="h-4 w-4" />
                          Official Partner
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1.5 bg-amber-500/10 text-amber-400 px-2.5 py-1 rounded-full text-xs font-semibold border border-amber-500/20">
                          <Info className="h-4 w-4" />
                          Pending Review
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-right">
                      {venue.isVerified ? (
                        <span className="text-xs text-emerald-400 font-medium inline-flex items-center gap-1">
                          <Check className="h-3.5 w-3.5" />
                          Verified
                        </span>
                      ) : canVerify ? (
                        <button
                          onClick={() => handleVerify(venue.id)}
                          disabled={activeVerifyVenueId === venue.id}
                          className="bg-amber-500 hover:bg-amber-600 text-slate-950 text-xs font-bold px-3 py-1.5 rounded-lg transition-colors inline-flex items-center gap-1 cursor-pointer disabled:opacity-50"
                        >
                          {activeVerifyVenueId === venue.id ? (
                            <Loader2 className="h-3 w-3 animate-spin" />
                          ) : (
                            <ShieldCheck className="h-3.5 w-3.5" />
                          )}
                          Approve Gym
                        </button>
                      ) : (
                        <span className="text-xs text-slate-600 italic">No actions</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Pagination bar */}
        {!isLoading && !isError && totalPages > 1 && (
          <div className="bg-brand-bg border-t border-slate-800 px-6 py-4 flex items-center justify-between">
            <span className="text-sm text-slate-500">
              Showing page {currentPage} of {totalPages}
            </span>
            <div className="flex gap-2">
              <button
                disabled={currentPage === 1}
                onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                className="px-3 py-1 bg-brand-panel border border-slate-700 text-sm font-medium text-slate-300 rounded-md hover:bg-brand-raised transition-colors cursor-pointer disabled:opacity-50"
              >
                Previous
              </button>
              <button
                disabled={currentPage === totalPages}
                onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
                className="px-3 py-1 bg-brand-panel border border-slate-700 text-sm font-medium text-slate-300 rounded-md hover:bg-brand-raised transition-colors cursor-pointer disabled:opacity-50"
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
