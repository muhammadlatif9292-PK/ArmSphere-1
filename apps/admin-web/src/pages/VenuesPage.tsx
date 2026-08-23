import React, { useState, useMemo } from 'react';
import { 
  Building2, 
  Search, 
  CheckCircle, 
  XCircle, 
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
    <div className="space-y-6 p-6 max-w-7xl mx-auto" id="venues-page-container">
      {/* Page Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between space-y-4 md:space-y-0">
        <div>
          <h1 className="text-3xl font-sans font-bold text-gray-900 tracking-tight flex items-center gap-3">
            <Building2 className="h-8 w-8 text-indigo-600" />
            Venue Partners
          </h1>
          <p className="text-sm text-gray-500 mt-1">
            Directory of official gyms, training clubs, and venues. Approve official venue badges.
          </p>
        </div>
        <button 
          onClick={() => refetch()}
          disabled={isLoading}
          className="inline-flex items-center gap-2 bg-white border border-gray-300 rounded-lg px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors shadow-xs cursor-pointer"
        >
          <RefreshCw className={`h-4 w-4 ${isLoading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-xs flex items-center gap-4">
          <div className="p-3 bg-indigo-50 rounded-lg text-indigo-600">
            <Building2 className="h-6 w-6" />
          </div>
          <div>
            <p className="text-sm text-gray-500 font-medium">Total Partners</p>
            <p className="text-2xl font-bold text-gray-900">{totalCount}</p>
          </div>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-xs flex items-center gap-4">
          <div className="p-3 bg-emerald-50 rounded-lg text-emerald-600">
            <CheckCircle className="h-6 w-6" />
          </div>
          <div>
            <p className="text-sm text-gray-500 font-medium">Verified Official Gyms</p>
            <p className="text-2xl font-bold text-gray-900">{verifiedCount}</p>
          </div>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-xs flex items-center gap-4">
          <div className="p-3 bg-amber-50 rounded-lg text-amber-600">
            <Info className="h-6 w-6" />
          </div>
          <div>
            <p className="text-sm text-gray-500 font-medium">Pending Verification</p>
            <p className="text-2xl font-bold text-gray-900">{unverifiedCount}</p>
          </div>
        </div>
      </div>

      {/* Error Banners */}
      {actionError && (
        <div className="bg-red-50 border border-red-200 text-red-800 p-4 rounded-lg flex items-center gap-3 text-sm">
          <XCircle className="h-5 w-5 text-red-600 shrink-0" />
          <span>{actionError}</span>
        </div>
      )}

      {/* Search and Filters panel */}
      <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-xs space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Search bar */}
          <div className="relative">
            <Search className="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
            <input 
              type="text" 
              placeholder="Search by gym name or address..."
              value={searchQuery}
              onChange={handleSearchChange}
              className="w-full bg-white border border-gray-300 rounded-lg pl-9 pr-4 py-2 text-sm text-gray-900 placeholder-gray-400 focus:outline-hidden focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
            />
          </div>

          {/* Province selector */}
          <select 
            value={provinceFilter}
            onChange={handleProvinceChange}
            className="bg-white border border-gray-300 rounded-lg px-3 py-2 text-sm text-gray-900 focus:outline-hidden focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
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
            className="bg-white border border-gray-300 rounded-lg px-3 py-2 text-sm text-gray-900 focus:outline-hidden focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
          >
            <option value="">All Cities</option>
            {citiesList.map(city => (
              <option key={city} value={city}>{city}</option>
            ))}
          </select>
        </div>
      </div>

      {/* Venues Table Card */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-xs overflow-hidden">
        {isLoading ? (
          <div className="p-12 flex flex-col items-center justify-center gap-3">
            <Loader2 className="h-8 w-8 text-indigo-600 animate-spin" />
            <p className="text-sm text-gray-500">Loading venue directory...</p>
          </div>
        ) : isError ? (
          <div className="p-12 text-center">
            <XCircle className="h-12 w-12 text-red-500 mx-auto mb-3" />
            <p className="text-gray-900 font-medium">Failed to load venues</p>
            <p className="text-sm text-gray-500 mt-1">{error?.message || 'Unknown network error.'}</p>
          </div>
        ) : filteredVenues.length === 0 ? (
          <div className="p-12 text-center text-gray-500">
            <Building2 className="h-12 w-12 text-gray-300 mx-auto mb-3" />
            <p className="text-gray-900 font-medium">No venues found</p>
            <p className="text-sm mt-1">Try resetting filters or searching for something else.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-200 text-xs font-semibold text-gray-500 uppercase tracking-wider">
                  <th className="px-6 py-4">Logo & Name</th>
                  <th className="px-6 py-4">Location</th>
                  <th className="px-6 py-4">Contact Info</th>
                  <th className="px-6 py-4">Verified Gym Partner</th>
                  <th className="px-6 py-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 text-sm">
                {paginatedVenues.map((venue) => (
                  <tr key={venue.id} className="hover:bg-gray-50/50 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-4">
                        <div className="h-10 w-10 rounded-lg bg-gray-100 border border-gray-200 flex items-center justify-center overflow-hidden shrink-0">
                          {venue.logoUrl ? (
                            <img src={venue.logoUrl} alt={venue.name} className="h-full w-full object-cover" />
                          ) : (
                            <Building2 className="h-5 w-5 text-gray-400" />
                          )}
                        </div>
                        <div>
                          <p className="font-semibold text-gray-900">{venue.name}</p>
                          {venue.description && (
                            <p className="text-xs text-gray-500 max-w-sm truncate mt-0.5">{venue.description}</p>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-start gap-1 text-gray-700">
                        <MapPin className="h-4 w-4 text-gray-400 shrink-0 mt-0.5" />
                        <div>
                          <p className="text-gray-900">{venue.address}</p>
                          <p className="text-xs text-gray-500">{venue.city}, {venue.province}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      {venue.contactInfo ? (
                        <div className="flex items-center gap-1.5 text-gray-600">
                          <PhoneCall className="h-3.5 w-3.5 text-gray-400" />
                          <span>{venue.contactInfo}</span>
                        </div>
                      ) : (
                        <span className="text-gray-400 font-mono text-xs">--</span>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      {venue.isVerified ? (
                        <span className="inline-flex items-center gap-1.5 bg-emerald-50 text-emerald-700 px-2.5 py-1 rounded-full text-xs font-semibold">
                          <ShieldCheck className="h-4 w-4" />
                          Official Partner
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1.5 bg-amber-50 text-amber-700 px-2.5 py-1 rounded-full text-xs font-semibold">
                          <Info className="h-4 w-4" />
                          Pending Review
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-right">
                      {venue.isVerified ? (
                        <span className="text-xs text-emerald-600 font-medium inline-flex items-center gap-1">
                          <Check className="h-3.5 w-3.5" />
                          Verified
                        </span>
                      ) : canVerify ? (
                        <button
                          onClick={() => handleVerify(venue.id)}
                          disabled={activeVerifyVenueId === venue.id}
                          className="bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-semibold px-3 py-1.5 rounded-lg transition-colors shadow-xs inline-flex items-center gap-1 cursor-pointer disabled:opacity-50"
                        >
                          {activeVerifyVenueId === venue.id ? (
                            <Loader2 className="h-3 w-3 animate-spin" />
                          ) : (
                            <ShieldCheck className="h-3.5 w-3.5" />
                          )}
                          Approve Gym
                        </button>
                      ) : (
                        <span className="text-xs text-gray-400 italic">No actions</span>
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
          <div className="bg-white border-t border-gray-100 px-6 py-4 flex items-center justify-between">
            <span className="text-sm text-gray-500">
              Showing page {currentPage} of {totalPages}
            </span>
            <div className="flex gap-2">
              <button
                disabled={currentPage === 1}
                onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
                className="px-3 py-1 bg-white border border-gray-200 text-sm font-medium text-gray-700 rounded-md hover:bg-gray-50 transition-colors cursor-pointer disabled:opacity-50"
              >
                Previous
              </button>
              <button
                disabled={currentPage === totalPages}
                onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
                className="px-3 py-1 bg-white border border-gray-200 text-sm font-medium text-gray-700 rounded-md hover:bg-gray-50 transition-colors cursor-pointer disabled:opacity-50"
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
