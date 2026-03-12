import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { 
  HomeIcon, 
  CalendarIcon, 
  UserGroupIcon,
  ChartBarIcon,
 LogoutIcon
} from '@heroicons/react/24/outline';

const navigation = {
  PLAYER: [
    { name: 'Home', href: '/player', icon: HomeIcon },
    { name: 'My Bookings', href: '/player/bookings', icon: CalendarIcon },
    { name: 'Tournaments', href: '/player/tournaments', icon: UserGroupIcon },
  ],
  OWNER: [
    { name: 'Dashboard', href: '/owner', icon: ChartBarIcon },
    { name: 'My Futsals', href: '/owner/futsals', icon: HomeIcon },
    { name: 'Bookings', href: '/owner/bookings', icon: CalendarIcon },
    { name: 'Tournaments', href: '/owner/tournaments', icon: UserGroupIcon },
  ],
  ADMIN: [
    { name: 'Dashboard', href: '/admin', icon: ChartBarIcon },
    { name: 'Users', href: '/admin/users', icon: UserGroupIcon },
    { name: 'Futsals', href: '/admin/futsals', icon: HomeIcon },
    { name: 'Reports', href: '/admin/reports', icon: ChartBarIcon },
  ],
};

export default function MainLayout({ children }) {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  
  const navigationItems = navigation[user?.role] || [];

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Sidebar */}
      <div className="fixed inset-y-0 left-0 w-64 bg-white shadow-lg">
        <div className="flex items-center justify-center h-16 bg-green-600">
          <h1 className="text-white text-xl font-bold">Futsal System</h1>
        </div>
        
        <nav className="mt-8">
          {navigationItems.map((item) => (
            <Link
              key={item.name}
              to={item.href}
              className="flex items-center px-6 py-3 text-gray-600 hover:bg-gray-50 hover:text-green-600"
            >
              <item.icon className="h-5 w-5 mr-3" />
              {item.name}
            </Link>
          ))}
        </nav>
        
        <div className="absolute bottom-0 w-64 p-4 border-t">
          <div className="mb-4 px-2">
            <p className="text-sm text-gray-600">Signed in as</p>
            <p className="font-semibold truncate">{user?.fullName}</p>
            <p className="text-xs text-gray-500 capitalize">{user?.role}</p>
          </div>
          <button
            onClick={handleLogout}
            className="flex items-center w-full px-4 py-2 text-red-600 hover:bg-red-50 rounded-lg"
          >
            <LogoutIcon className="h-5 w-5 mr-3" />
            Logout
          </button>
        </div>
      </div>

      {/* Main Content */}
      <div className="ml-64 p-8">
        {children}
      </div>
    </div>
  );
}