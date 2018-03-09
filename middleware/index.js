/**
 * General middleware.
 */
"use strict";

module.exports = {
    logIncomingToConsole: logIncomingToConsole,
    authenticatedOrLogin: authenticatedOrLogin
};



/**
 * Check that kund is authenticated or redirect to login.
 *
 * @return {void}
 */
function authenticatedOrLogin(req, res, next) {
    //console.info("Authentication check through session.");

    if (req.session && req.session.kundID) {
        return next();
    }

    console.info("User is not authenticated.");
    console.info("Redirecting to /bank/login.");
    res.redirect("/bank/login");
}



/**
 * Log incoming requests to console to see who accesses the server
 * on what route.
 *
 * @param {Request}  req  The incoming request.
 * @param {Response} res  The outgoing response.
 * @param {Function} next Next to call in chain of middleware.
 *
 * @returns {void}
 */
function logIncomingToConsole(req, res, next) {
    console.info(`Got request on ${req.path} (${req.method}).`);
    next();
}
