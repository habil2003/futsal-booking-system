import React, { useState, useEffect } from 'react';
import { futsals } from '../../services/api';
import toast from 'react-hot-toast';

export default function OwnerFutsals() {
  const [myFutsals, setMyFutsals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAddForm, setShowAddForm] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    address: '',
    basePrice: '',
    images: []
  });

  useEffect(() => {
    loadFutsals();
  }, []);

  const loadFutsals = async () => {
    try {
      const response = await futsals.getAll();
      // In a real app, you'd filter by owner ID from the backend
      setMyFutsals(response.data.futsals || []);
    } catch (error) {
      toast.error('Failed to load futsals');
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await futsals.create(formData);
      toast.success('Futsal created successfully! Waiting for admin approval.');
      setShowAddForm(false);
      setFormData({ name: '', description: '', address: '', basePrice: '', images: [] });
      loadFutsals();
    } catch (error) {
      toast.error('Failed to create futsal');
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600"></div>
      </div>
    );
  }

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold text-gray-900">My Futsals</h1>
        <button
          onClick={() => setShowAddForm(!showAddForm)}
          className="btn-primary"
        >
          {showAddForm ? 'Cancel' : 'Add New Futsal'}
        </button>
      </div>

      {/* Add Form */}
      {showAddForm && (
        <div className="card p-6 mb-6">
          <h2 className="text-xl font-semibold mb-4">Add New Futsal</h2>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Futsal Name *
              </label>
              <input
                type="text"
                name="name"
                value={formData.name}
                onChange={handleInputChange}
                required
                className="input-field"
                placeholder="e.g., Green Field Futsal"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Description
              </label>
              <textarea
                name="description"
                value={formData.description}
                onChange={handleInputChange}
                rows="3"
                className="input-field"
                placeholder="Describe your futsal..."
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Address *
              </label>
              <input
                type="text"
                name="address"
                value={formData.address}
                onChange={handleInputChange}
                required
                className="input-field"
                placeholder="e.g., Lakeside, Pokhara"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Base Price (per hour) *
              </label>
              <input
                type="number"
                name="basePrice"
                value={formData.basePrice}
                onChange={handleInputChange}
                required
                min="0"
                step="100"
                className="input-field"
                placeholder="e.g., 1500"
              />
            </div>

            <button
              type="submit"
              className="btn-primary w-full"
            >
              Create Futsal
            </button>
          </form>
        </div>
      )}

      {/* Futsals Grid */}
      {myFutsals.length === 0 ? (
        <div className="text-center py-12">
          <div className="text-6xl mb-4">⚽</div>
          <h3 className="text-xl font-medium text-gray-900 mb-2">No Futsals Yet</h3>
          <p className="text-gray-500 mb-4">Get started by adding your first futsal</p>
          <button
            onClick={() => setShowAddForm(true)}
            className="btn-primary"
          >
            Add Your First Futsal
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {myFutsals.map((futsal) => (
            <div key={futsal.id} className="card overflow-hidden">
              {futsal.images && futsal.images[0] ? (
                <img 
                  src={futsal.images[0]} 
                  alt={futsal.name}
                  className="w-full h-48 object-cover"
                />
              ) : (
                <div className="w-full h-48 bg-gray-200 flex items-center justify-center">
                  <span className="text-4xl">⚽</span>
                </div>
              )}
              <div className="p-4">
                <div className="flex justify-between items-start">
                  <h3 className="text-xl font-semibold">{futsal.name}</h3>
                  <span className={`px-2 py-1 text-xs rounded-full ${
                    futsal.isApproved 
                      ? 'bg-green-100 text-green-800' 
                      : 'bg-yellow-100 text-yellow-800'
                  }`}>
                    {futsal.isApproved ? 'Approved' : 'Pending'}
                  </span>
                </div>
                <p className="text-gray-600 mt-1">{futsal.address}</p>
                <p className="text-sm text-gray-500 mt-2 line-clamp-2">
                  {futsal.description || 'No description provided'}
                </p>
                <div className="mt-4 flex justify-between items-center">
                  <span className="text-green-600 font-bold text-lg">
                    NPR {futsal.basePrice}/hr
                  </span>
                  <div className="space-x-2">
                    <button className="text-blue-600 hover:text-blue-800">
                      Edit
                    </button>
                    <button className="text-green-600 hover:text-green-800">
                      Slots
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}