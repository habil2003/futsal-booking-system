import React, { useState, useEffect } from 'react';
import { futsals } from '../../services/api';
import { Link } from 'react-router-dom';
import { StarIcon, MapPinIcon } from '@heroicons/react/solid';

export default function PlayerHome() {
  const [futsalsList, setFutsalsList] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    loadFutsals();
  }, []);

  const loadFutsals = async () => {
    try {
      const response = await futsals.getAll();
      setFutsalsList(response.data.futsals || []);
    } catch (error) {
      console.error('Error loading futsals:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredFutsals = futsalsList.filter(futsal =>
    futsal.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    futsal.address.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600"></div>
      </div>
    );
  }

  return (
    <div>
      {/* Hero Section */}
      <div className="bg-gradient-to-r from-green-600 to-green-800 -mt-8 -mx-8 p-8 mb-8">
        <div className="max-w-7xl mx-auto">
          <h1 className="text-4xl font-bold text-white mb-4">
            Find Your Perfect Futsal
          </h1>
          <p className="text-green-100 text-lg mb-6">
            Book futsal slots in Pokhara with ease
          </p>
          
          {/* Search Bar */}
          <div className="max-w-2xl">
            <div className="relative">
              <input
                type="text"
                placeholder="Search by name or location..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full px-4 py-3 pl-12 pr-4 rounded-lg focus:outline-none focus:ring-2 focus:ring-white"
              />
              <svg
                className="absolute left-4 top-3.5 h-5 w-5 text-gray-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                />
              </svg>
            </div>
          </div>
        </div>
      </div>

      {/* Futsals Grid */}
      {filteredFutsals.length === 0 ? (
        <div className="text-center py-12">
          <div className="text-6xl mb-4">🏟️</div>
          <h3 className="text-xl font-medium text-gray-900 mb-2">No Futsals Found</h3>
          <p className="text-gray-500">Try adjusting your search</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredFutsals.map((futsal) => (
            <Link
              key={futsal.id}
              to={`/player/futsal/${futsal.id}`}
              className="card hover:shadow-lg transition-shadow"
            >
              {futsal.images && futsal.images[0] ? (
                <img 
                  src={futsal.images[0]} 
                  alt={futsal.name}
                  className="w-full h-48 object-cover"
                />
              ) : (
                <div className="w-full h-48 bg-gradient-to-br from-green-400 to-green-600 flex items-center justify-center">
                  <span className="text-6xl">⚽</span>
                </div>
              )}
              
              <div className="p-4">
                <h3 className="text-xl font-semibold text-gray-900 mb-2">
                  {futsal.name}
                </h3>
                
                <div className="flex items-center text-gray-600 mb-2">
                  <MapPinIcon className="h-4 w-4 mr-1" />
                  <span className="text-sm">{futsal.address}</span>
                </div>
                
                <div className="flex items-center mb-3">
                  <div className="flex items-center mr-2">
                    <StarIcon className="h-4 w-4 text-yellow-400" />
                    <span className="ml-1 text-sm font-medium">
                      {futsal.averageRating || '0.0'}
                    </span>
                  </div>
                  <span className="text-sm text-gray-500">
                    ({futsal.reviews?.length || 0} reviews)
                  </span>
                </div>
                
                <div className="flex justify-between items-center">
                  <div>
                    <span className="text-2xl font-bold text-green-600">
                      NPR {futsal.basePrice}
                    </span>
                    <span className="text-sm text-gray-500">/hour</span>
                  </div>
                  
                  <button className="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition-colors">
                    Book Now
                  </button>
                </div>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}