import React, { useState, useEffect } from 'react';
import { futsals, bookings } from '../../services/api';
import {
  ChartBarIcon,
  CalendarIcon,
  CurrencyDollarIcon,
  UserGroupIcon,
  CheckCircleIcon,
  XCircleIcon
} from '@heroicons/react/outline';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell
} from 'recharts';
import toast from 'react-hot-toast';

export default function AdminDashboard() {
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalFutsals: 0,
    totalBookings: 0,
    totalRevenue: 0,
    pendingFutsals: 0,
    pendingApprovals: 0
  });
  const [recentActivity, setRecentActivity] = useState([]);
  const [pendingFutsals, setPendingFutsals] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      // Load all futsals
      const futsalsRes = await futsals.getAll();
      const allFutsals = futsalsRes.data.futsals || [];
      
      // Calculate stats
      const pendingApprovals = allFutsals.filter(f => !f.isApproved).length;
      
      setStats({
        totalUsers: 156, // This should come from a users API endpoint
        totalFutsals: allFutsals.length,
        totalBookings: 89, // This should come from bookings API
        totalRevenue: 45000,
        pendingFutsals: pendingApprovals,
        pendingApprovals: pendingApprovals
      });

      setPendingFutsals(allFutsals.filter(f => !f.isApproved).slice(0, 5));
      
      // Mock recent activity
      setRecentActivity([
        { id: 1, action: 'New futsal registration', user: 'Green Field', time: '5 mins ago', status: 'pending' },
        { id: 2, action: 'Booking confirmed', user: 'John Doe', time: '10 mins ago', status: 'completed' },
        { id: 3, action: 'New user registered', user: 'Sarah Smith', time: '15 mins ago', status: 'completed' },
        { id: 4, action: 'Payment received', user: 'Mike Johnson', time: '20 mins ago', status: 'completed' },
      ]);
    } catch (error) {
      console.error('Error loading dashboard data:', error);
      toast.error('Failed to load dashboard data');
    } finally {
      setLoading(false);
    }
  };

  const handleApproveFutsal = async (futsalId) => {
    try {
      // Add API call to approve futsal
      toast.success('Futsal approved successfully');
      loadDashboardData();
    } catch (error) {
      toast.error('Failed to approve futsal');
    }
  };

  const handleRejectFutsal = async (futsalId) => {
    try {
      // Add API call to reject futsal
      toast.success('Futsal rejected');
      loadDashboardData();
    } catch (error) {
      toast.error('Failed to reject futsal');
    }
  };

  const statCards = [
    { 
      name: 'Total Users', 
      value: stats.totalUsers, 
      icon: UserGroupIcon, 
      change: '+12%',
      color: 'bg-blue-500'
    },
    { 
      name: 'Total Futsals', 
      value: stats.totalFutsals, 
      icon: ChartBarIcon, 
      change: '+8%',
      color: 'bg-green-500'
    },
    { 
      name: 'Total Bookings', 
      value: stats.totalBookings, 
      icon: CalendarIcon, 
      change: '+15%',
      color: 'bg-purple-500'
    },
    { 
      name: 'Total Revenue', 
      value: `NPR ${stats.totalRevenue.toLocaleString()}`, 
      icon: CurrencyDollarIcon, 
      change: '+10%',
      color: 'bg-yellow-500'
    },
  ];

  const pieData = [
    { name: 'Active Futsals', value: stats.totalFutsals - stats.pendingFutsals },
    { name: 'Pending Approval', value: stats.pendingFutsals },
  ];

  const COLORS = ['#16a34a', '#f59e0b'];

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600"></div>
      </div>
    );
  }

  return (
    <div>
      <h1 className="text-3xl font-bold text-gray-900 mb-8">Admin Dashboard</h1>
      
      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {statCards.map((stat, index) => (
          <div key={index} className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-500 text-sm">{stat.name}</p>
                <p className="text-2xl font-bold mt-1">{stat.value}</p>
                <p className="text-xs text-green-600 mt-2">{stat.change} from last month</p>
              </div>
              <div className={`${stat.color} p-3 rounded-lg bg-opacity-10`}>
                <stat.icon className={`h-8 w-8 ${stat.color.replace('bg-', 'text-')}`} />
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Charts and Pending Approvals */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
        {/* Pie Chart */}
        <div className="bg-white rounded-lg shadow p-6 lg:col-span-1">
          <h3 className="text-lg font-semibold mb-4">Futsal Status</h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={pieData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={80}
                  fill="#8884d8"
                  paddingAngle={5}
                  dataKey="value"
                  label
                >
                  {pieData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="flex justify-center space-x-4 mt-4">
            <div className="flex items-center">
              <div className="w-3 h-3 bg-green-600 rounded-full mr-2"></div>
              <span className="text-sm">Active ({stats.totalFutsals - stats.pendingFutsals})</span>
            </div>
            <div className="flex items-center">
              <div className="w-3 h-3 bg-yellow-500 rounded-full mr-2"></div>
              <span className="text-sm">Pending ({stats.pendingFutsals})</span>
            </div>
          </div>
        </div>

        {/* Recent Activity */}
        <div className="bg-white rounded-lg shadow p-6 lg:col-span-2">
          <h3 className="text-lg font-semibold mb-4">Recent Activity</h3>
          <div className="space-y-4">
            {recentActivity.map((activity) => (
              <div key={activity.id} className="flex items-center justify-between border-b pb-3 last:border-0 last:pb-0">
                <div className="flex items-center space-x-3">
                  {activity.status === 'pending' ? (
                    <XCircleIcon className="h-5 w-5 text-yellow-500" />
                  ) : (
                    <CheckCircleIcon className="h-5 w-5 text-green-500" />
                  )}
                  <div>
                    <p className="font-medium">{activity.action}</p>
                    <p className="text-sm text-gray-500">by {activity.user}</p>
                  </div>
                </div>
                <span className="text-xs text-gray-400">{activity.time}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Pending Approvals */}
      {pendingFutsals.length > 0 && (
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex justify-between items-center mb-4">
            <h3 className="text-lg font-semibold">Pending Futsal Approvals</h3>
            <span className="bg-yellow-100 text-yellow-800 px-2 py-1 rounded-full text-xs">
              {pendingFutsals.length} pending
            </span>
          </div>
          
          <div className="space-y-4">
            {pendingFutsals.map((futsal) => (
              <div key={futsal.id} className="flex items-center justify-between border-b pb-4 last:border-0 last:pb-0">
                <div className="flex items-center space-x-4">
                  {futsal.images && futsal.images[0] ? (
                    <img 
                      src={futsal.images[0]} 
                      alt={futsal.name}
                      className="h-16 w-16 object-cover rounded-lg"
                    />
                  ) : (
                    <div className="h-16 w-16 bg-gray-200 rounded-lg flex items-center justify-center">
                      <span className="text-2xl">⚽</span>
                    </div>
                  )}
                  <div>
                    <h4 className="font-semibold">{futsal.name}</h4>
                    <p className="text-sm text-gray-600">{futsal.address}</p>
                    <p className="text-xs text-gray-500">Owner: {futsal.owner?.fullName || 'N/A'}</p>
                  </div>
                </div>
                <div className="flex space-x-2">
                  <button
                    onClick={() => handleApproveFutsal(futsal.id)}
                    className="bg-green-600 text-white px-3 py-1 rounded text-sm hover:bg-green-700"
                  >
                    Approve
                  </button>
                  <button
                    onClick={() => handleRejectFutsal(futsal.id)}
                    className="bg-red-600 text-white px-3 py-1 rounded text-sm hover:bg-red-700"
                  >
                    Reject
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}