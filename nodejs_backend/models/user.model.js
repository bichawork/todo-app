const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const { Schema } = mongoose;

const userSchema = new Schema(
    {
        email: {
            type: String,
            lowercase: true,
            required: [true, "user name can't be empty"],
            match: [
                /^([\w-\.]+@([\w-]+\.)+[\w-]{2,4})?$/,
                "userName format is not correct",
            ],
            unique: true,
        },
        password: {
            type: String,
            required: [true, "password is required"],
        },
    },
    { timestamps: true }
);

userSchema.pre('save', async function () {
    const user = this;
    if (!user.isModified('password')) {
        return;
    }
    try {
        const salt = await bcrypt.genSalt(10);
        const hash = await bcrypt.hash(user.password, salt);
        user.password = hash;
    } catch (err) {
        throw err;
    }
});

userSchema.methods.comparePassword = async function (candidatePassword) {
    try {
        return await bcrypt.compare(candidatePassword, this.password);
    } catch (err) {
        throw err;
    }
};

const UserModel = mongoose.model('user', userSchema);

module.exports = UserModel;