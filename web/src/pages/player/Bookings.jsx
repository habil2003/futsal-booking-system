import React, { useState, useEffect } from 'react';
import { bookings } from '../../services/api';
import { CalendarIcon, MapPinIcon } from '@heroicons/react/outline';
import toast from 'react-hot-toast';

export default function PlayerBookings() {
  const [myBookings, setMyBookings] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadBookings();
  }, []);

  const loadBookings = async () => {
    try {
      const response = await bookings.getMyBookings();
      setMyBookings(response.data.bookings || []);
    } catch (error) {
      toast.error('Failed to load bookings');
    } finally {
      setLoading(false);
    }
  };

  const handleCancel = async (bookingId) => {
    if (!window.confirm('Are you sure you want to cancel this booking?')) {
      return;
    }

    try {
      await bookings.cancel(bookingId);
      toast.success('Booking cancelled successfully');
      loadBookings();
    } catch (error) {
      toast.error('Failed to cancel booking');
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'CONFIRMED':
        return 'bg-green-100 text-green-800';
      case 'PENDING':
        return 'bg-yellow-100 text-yellow-800';
      case 'CANCELLED':
        return 'bg-red-100 text-red-800';
      case 'COMPLETED':
        return 'bg-blue-100 text-blue-800';
      default:
        return 'bg-gray-100 text-gray-800';
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
      <h1 className="text-3xl font-bold text-gray-900 mb-8">My Bookings</h1>

      {myBookings.length === 0 ? (
        <div className="text-center py-12">
          <div className="text-6xl mb-4">📅</div>
          <h3 className="text-xl font-medium text-gray-900 mb-2">No Bookings Yet</h3>
          <p className="text-gray-500 mb-4">Start by booking a futsal slot</p>
          <a
            href="/player"
            className="btn-primary inline-block"
          >
            Browse Futsals
          </a>
        </div>
      ) : (
        <div className="space-y-4">
          {myBookings.map((booking) => (
            <div key={booking.id} className="card p-6">
              <div className="flex flex-col md:flex-row md:items-center md:justify-between">
                <div className="flex-1">
                  <div className="flex items-center mb-2">
                    <h3 className="text-xl font-semibold mr-3">
                      {booking.slot?.futsal?.name}
                    </h3>
                    <span className={`px-2 py-1 text-xs rounded-full ${getStatusColor(booking.status)}`}>
                      {booking.status}
                    </span>
                  </div>
                  
                  <div className="flex items-center text-gray-600 mb-2">
                    <MapPinIcon className="h-4 w-4 mr-1" />
                    <span className="text-sm">{booking.slot?.futsal?.address}</span>
                  </div>
                  
                  <div className="flex items-center text-gray-600 mb-4">
                    <CalendarIcon className="h-4 w-4 mr-1" />
                    <span className="text-sm">
                      {new Date(booking.slot?.date).toLocaleDateString()} • 
                      {booking.slot?.startTime} - {booking.slot?.endTime}
                    </span>
                  </div>
                  
                  <div className="flex items-center">
                    <span className="text-2xl font-bold text-green-600">
                      NPR {booking.totalPrice}
                    </span>
                    <span className="text-sm text-gray-500 ml-2">
                      • Booked on {new Date(booking.bookingDate).toLocaleDateString()}
                    </span>
                  </div>
                </div>
                
                {booking.status === 'PENDING' && (
                  <div className="mt-4 md:mt-0 md:ml-4">
                    <button
                      onClick={() => handleCancel(booking.id)}
                      className="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition-colors"
                    >
                      Cancel Booking
                    </button>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}