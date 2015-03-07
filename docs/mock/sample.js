module.exports = {
    "/exact/match/1": "exact.json",
    "/exact/match/2": "exact.mockjson",
    "/exact/match/3": "https://raw.githubusercontent.com/rinh/fekit/master/docs/mock/exact.json",
    "/exact/match/4": "exact.js",
    rules: [{
        pattern: "/exact/match/5",
        respondwith: "exact.json"
    }, {
        pattern: /^\/regex\/match\/a\/\d+/,
        respondwith: "regex.json",
        jsonp: "__jscallback"
    }, {
        pattern: /^\/regex\/match\/b\/\d+/,
        respondwith: function(req, res, context) {
            res.end(JSON.stringify(Object.keys(context)));
        }
    }]
};
