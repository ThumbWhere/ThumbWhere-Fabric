var connect = require('connect'),
    escort = require('escort');

connect(
    escort(function(routes) {
        routes.get("/", function(req, res) {
            res.end("Hello, world!");
        });
    })
).listen(3000);
