import { 
  verifyGoogleToken,
  verifyFacebookToken,
  findOrCreateSocialUser,
  generateAuthToken
} from '../services/socialAuth.service.js';

// ============================================
// GOOGLE LOGIN
// ============================================
export const googleLogin = async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ 
        status: 'error', 
        message: 'ID token is required' 
      });
    }

    const payload = await verifyGoogleToken(idToken);

    if (!payload || !payload.email) {
      return res.status(401).json({ 
        status: 'error', 
        message: 'Invalid Google token' 
      });
    }

    const profile = {
      id: payload.sub,
      email: payload.email,
      name: payload.name,
      picture: payload.picture
    };

    const user = await findOrCreateSocialUser(profile, 'GOOGLE');
    const token = generateAuthToken(user);

    res.json({
      status: 'success',
      message: 'Google login successful',
      token,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
        profileImage: user.profileImage,
        isApproved: user.isApproved
      }
    });

  } catch (error) {
    console.error('Google login error:', error);
    res.status(500).json({ 
      status: 'error', 
      message: 'Server error: ' + error.message 
    });
  }
};

// ============================================
// FACEBOOK LOGIN
// ============================================
export const facebookLogin = async (req, res) => {
  try {
    const { accessToken } = req.body;

    if (!accessToken) {
      return res.status(400).json({ 
        status: 'error', 
        message: 'Access token is required' 
      });
    }

    const payload = await verifyFacebookToken(accessToken);

    if (!payload || !payload.email) {
      return res.status(401).json({ 
        status: 'error', 
        message: 'Invalid Facebook token' 
      });
    }

    const profile = {
      id: payload.id,
      email: payload.email,
      name: payload.name,
      picture: payload.picture?.data?.url
    };

    const user = await findOrCreateSocialUser(profile, 'FACEBOOK');
    const token = generateAuthToken(user);

    res.json({
      status: 'success',
      message: 'Facebook login successful',
      token,
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
        profileImage: user.profileImage,
        isApproved: user.isApproved
      }
    });

  } catch (error) {
    console.error('Facebook login error:', error);
    res.status(500).json({ 
      status: 'error', 
      message: 'Server error: ' + error.message 
    });
  }
};