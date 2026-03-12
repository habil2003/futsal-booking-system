import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { AuthProvider, useAuth } from './context/AuthContext';
import LoginPage from './pages/LoginPage';
import OwnerDashboard from './pages/owner/Dashboard';
import OwnerFutsals from './pages/owner/Futsals';
import PlayerHome from './pages/player/Home';
import PlayerBookings from './pages/player/Bookings';
import AdminDashboard from './pages/admin/Dashboard';
import MainLayout from './layouts/MainLayout';

const PrivateRoute = ({ children, allowedRoles }) => {
  const { user, token, isLoading } = useAuth();
  
  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600"></div>
      </div>
    );
  }
  
  if (!token) {
    return <Navigate to="/login" />;
  }
  
  if (allowedRoles && !allowedRoles.includes(user?.role)) {
    return <Navigate to="/" />;
  }
  
  return <MainLayout>{children}</MainLayout>;
};

function AppRoutes() {
  const { user } = useAuth();
  
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      
      {/* Owner Routes */}
      <Route 
        path="/owner" 
        element={
          <PrivateRoute allowedRoles={['OWNER', 'ADMIN']}>
            <OwnerDashboard />
          </PrivateRoute>
        } 
      />
      <Route 
        path="/owner/futsals" 
        element={
          <PrivateRoute allowedRoles={['OWNER', 'ADMIN']}>
            <OwnerFutsals />
          </PrivateRoute>
        } 
      />
      
      {/* Player Routes */}
      <Route 
        path="/player" 
        element={
          <PrivateRoute allowedRoles={['PLAYER']}>
            <PlayerHome />
          </PrivateRoute>
        } 
      />
      <Route 
        path="/player/bookings" 
        element={
          <PrivateRoute allowedRoles={['PLAYER']}>
            <PlayerBookings />
          </PrivateRoute>
        } 
      />
      
      {/* Admin Routes */}
      <Route 
        path="/admin" 
        element={
          <PrivateRoute allowedRoles={['ADMIN']}>
            <AdminDashboard />
          </PrivateRoute>
        } 
      />
      
      {/* Default redirect based on role */}
      <Route 
        path="/" 
        element={
          user?.role === 'OWNER' ? <Navigate to="/owner" /> :
          user?.role === 'ADMIN' ? <Navigate to="/admin" /> :
          <Navigate to="/player" />
        } 
      />
    </Routes>
  );
}

function App() {
  return (
    <Router>
      <AuthProvider>
        <Toaster 
          position="top-right"
          toastOptions={{
            duration: 4000,
            style: {
              background: '#363636',
              color: '#fff',
            },
          }}
        />
        <AppRoutes />
      </AuthProvider>
    </Router>
  );
}

export default App;

