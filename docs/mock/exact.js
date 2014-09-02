module.exports = function(req, res, context) {
    res.end(JSON.stringify({
        "exact": true
    }));
};
