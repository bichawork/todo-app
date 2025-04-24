const UserServices = require('../services/user.service');

exports.register = async (req, res, next) => {
    try {
       
        const { email, password } = req.body;
        if (!email || !password) {
            throw new Error('Email and password are required');
        }
        const duplicate = await UserServices.getUserByEmail(email);
        if (duplicate) {
            throw new Error(`UserName ${email}, Already Registered`);
        }
        await UserServices.registerUser(email, password);
        res.json({ status: true, success: 'User registered successfully' });
    } catch (err) {
        console.error("---> err -->", err.message);
        next(err);
    }
};

exports.login = async (req, res, next) => {
    try {
       
        const { email, password } = req.body;
        if (!email || !password) {
            throw new Error('Email and password are required');
        }
        const user = await UserServices.getUserByEmail(email);
        if (!user) {
            throw new Error('User does not exist');
        }
     
        const isPasswordCorrect = await user.comparePassword(password);
        
        if (!isPasswordCorrect) {
            throw new Error('Username or Password does not match');
        }
        const tokenData = { _id: user._id, email: user.email };
        const token = await UserServices.generateAccessToken(tokenData, "secret", "1h");
        res.status(200).json({ status: true, success: "sendData", token });
    } catch (error) {
        console.error('Login error:', error.message);
        next(error);
    }
};

// Error handling middleware
exports.errorHandler = (err, req, res, next) => {
    console.error('Error:', err.message);
    res.status(500).json({ status: false, error: err.message || 'Server error' });
};