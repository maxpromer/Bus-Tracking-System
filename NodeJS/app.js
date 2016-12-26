var mongodb = require('mongodb');
var exp = require('express')();
var bodyParser = require('body-parser');
var server = require('http').Server(exp);
// var io = require('socket.io')(server);
var net = require('net');
var buf = require('./buffer');

var config = {
	mongodb: {
		host: "<Can not be revealed>",
		port: 27017,
		database: "bus"
	},
	http: {
		port: 85
	},
	tcp: {
		port: 86
	}
};

// parse application/json
exp.use(bodyParser.urlencoded({
    extended: true
}));
exp.use(bodyParser.json());

var MongoClient = mongodb.MongoClient;
var url = `mongodb://${config.mongodb.host}:${config.mongodb.port}/${config.mongodb.database}`;
var _clients = [];

var mogoConect = (callback) => {
	MongoClient.connect(url, callback);
}

/* Routing */
exp.all('/*', function(req, res, next) {
	res.header("Access-Control-Allow-Origin", "*");
	res.header("Access-Control-Allow-Headers", "X-Requested-With");
	next();
});

exp.get('/', (req, res) => {
    res.send('<h1>Hello, my name is Sonthaya Nongnuch</h1>');
});

var docs;

exp.get("/track", (req, res) => {
	mogoConect((err, db) => {
		if (err) {
			console.error(`Unable to connect to the mongoDB server. Error:${err}`);
			res.json({e: true, msg: `Unable to connect to the mongoDB server. Error:${err}`});
			return;
		}
		
		var collection = db.collection('track');
		
		req.query["install"] = true;
		collection.find(req.query, {_id: 0}).toArray(function (err, docs) {
			if (err) {
				res.json({e: true, msg: "mongodb error : " + err});
			} else {
				for (var index=0;index<docs.length;index++) {
					var find = buf.findByImei(docs[index].imei);
					if (find !== false) {
						docs[index].latitude = find.latitude;
						docs[index].longitude = find.longitude;
						docs[index].speedkm = find.speedkm;
						docs[index].online = true;
					} else {
						docs[index].online = false;
					}
					docs[index].before = [];
				}
				
				var collection = db.collection('log');
				findLog(collection, docs, 0, function(err, docs) {
					if (err) {
						res.json({e: true, msg: "mongodb error : " + err});
					} else {
						res.json({e: false, data: docs});
						db.close();
					}
				});
			}
			
		});
	});
});

function findLog(collection, docs, next, callback) {
	collection.find({imei: docs[next].imei}, {_id: 0, imei: 0, update: 0}).sort({update: -1}).skip(1).limit(5).toArray(function(err, docLog) {
		if (err) {
			callback(err);
			return;
		}
		docs[next].before = docLog;
		if (++next != docs.length)
			findLog(collection, docs, next, callback);
		else
			callback(false, docs);
	});
}

exp.post("/track", (req, res) => {	
	var post = req.body;
	if (typeof post.imei !== "string") {
		res.json({e: true, msg: "'imei' not found"});
		return;
	}
	if (typeof post.name !== "string") post.name = "";
	if (typeof post.driver !== "string") post.driver = "";
	if (typeof post.car_number !== "number") post.car_number = -1;
	if (typeof post.latitude !== "number") post.latitude = 0;
	if (typeof post.longitude !== "number") post.longitude = 0;
	if (typeof post.speedkm !== "number") post.speedkm = 0;
	
	mogoConect((err, db) => {
		if (err) {
			console.error(`Unable to connect to the mongoDB server. Error:${err}`);
			res.json({e: true, msg: `Unable to connect to the mongoDB server. Error:${err}`});
			return;
		}
		
		var collection = db.collection('track');
		
		collection.insert({
			imei: post.imei, 
			name: post.name, 
			driver: post.driver, 
			car_number: post.car_number,
			latitude: post.latitude,
			longitude: post.longitude,
			speedkm: post.speedkm,
			update: Math.floor(new Date().getTime() / 1000)
		}, (err, result) => {
			if (err) {
				res.json({e: true, msg: `mongodb error : ${err}`});
			} else {
				res.json({e: false});
			}
			db.close();
		});
	});
});

exp.get("/track/:imei", (req, res) => {
	var find = buf.findByImei(req.params.imei);

	mogoConect((err, db) => {
		if (err) {
			console.error(`Unable to connect to the mongoDB server. Error:${err}`);
			res.json({e: true, msg: `Unable to connect to the mongoDB server. Error:${err}`});
			return;
		}
		
		var collection = db.collection('track');
				
		collection.findOne({imei: req.params.imei}, (err, doc) => {
			if (err) {
				res.json({e: true, msg: `mongodb error : ${err}`});
			} else {
				if (doc === null) {
					res.json({e: true, msg: "not found"});
				} else {
					delete doc._id;
					if (find !== false) {
						doc.latitude = find.latitude;
						doc.longitude = find.longitude;
						doc.speedkm = find.speedkm;
						doc.online = true;
					} else {
						doc.online = false;
					}
					res.json({e: false, data: doc});
				}
			}
			db.close();
		}); 
	});
});

exp.post("/track/:imei", (req, res) => {
	var imei = req.params.imei;
	var post = req.body;
	
	if (typeof post.lat === "undefined" || typeof post.long === "undefined") {
		res.json({e: true, msg: "'lat' or 'long' not found"});
		return ;
	}
	if (typeof post.speedkm === "undefined") 
		post.speedkm = 0;
	
	post.lat = parseFloat(post.lat);
	post.long = parseFloat(post.long);
	post.speedkm = parseFloat(post.speedkm);
	
	mogoConect((err, db) => {
		if (err) {
			console.error(`Unable to connect to the mongoDB server. Error:${err}`);
			res.json({e: true, msg: `Unable to connect to the mongoDB server. Error:${err}`});
			return;
		}
		
		var collection = db.collection('track');
		
		collection.count({imei: req.params.imei}, (err, count) => {
			if (err) {
				res.json({e: true, msg: `mongodb error : ${err}`});
			} else {	
				if (count == 0) {
					res.json({e: true, msg: `not found imei : ${imei}`});
					db.close();
				} else {
					var collection = db.collection('log');
		
					collection.insert({
						imei: req.params.imei, 
						latitude: post.lat,
						longitude: post.long,
						speedkm: post.speedkm,
						update: Math.floor(new Date().getTime() / 1000)
					}, (err, result) => {
						if (err) {
							res.json({e: true, msg: `mongodb error : ${err}`});
						} else {	
							res.json({e: false});
						}
						db.close();
					});
					
					buf.Update(imei, {lat: post.lat, long: post.long, speedkm: post.speedkm});
				}
			}
		});
	});
});

exp.get("/track/:imei/history", (req, res) => {
	var imei = req.params.imei;
	
	mogoConect((err, db) => {
		if (err) {
			console.error(`Unable to connect to the mongoDB server. Error:${err}`);
			return;
		}
		
		var collection = db.collection('log');
		
		collection.find({imei: imei}).sort({update: 1}).toArray((err, docs) => {
			if (err) {
				console.error(`mongodb error : ${err}`);
			} else {
				var groupTime = [];
				var lastTime = 0;
				var i_groupTime = 0;
				for (var i=0;i<docs.length;i++) {
					if (i == 0) {
						groupTime[0] = {};
						groupTime[0]['start'] = docs[i].update;
					}
					if (docs[i].update > lastTime + 90 && i != 0) {
						groupTime[i_groupTime]['end'] = docs[i-1].update;
						groupTime[++i_groupTime] = {};
						groupTime[i_groupTime]['start'] = docs[i].update;
					}
					lastTime = docs[i].update;
				}
				groupTime[i_groupTime]['end'] = lastTime;
				res.json({e: false, data: groupTime});
				db.close();
			}
		});
	});
});

exp.get("/track/:imei/log", (req, res) => {
	var imei = req.params.imei;
	var start = typeof req.query['start'] === "undefined" ? -1 : parseInt(req.query['start']);
	var end = typeof req.query['end'] === "undefined" ? -1 : parseInt(req.query['end']);
	
	if (start == -1 || end == -1) {
		res.json({e: true, data: 'start or end undefined.'});
		return;
	}

	mogoConect((err, db) => {
		if (err) {
			console.error(`Unable to connect to the mongoDB server. Error:${err}`);
			return;
		}
		
		var collection = db.collection('log');
		
		collection.find({imei: imei, update: {$gte: start, $lte: end}}, {_id: 0, imei: 0}).sort({update: 1}).toArray((err, docs) => {
			if (err) {
				console.error(`mongodb error : ${err}`);
			} else {
				res.json({e: false, data: docs});
				db.close();
			}
		});
	});
});
	
exp.get("/buffer", (req, res) => {
	res.json({e: false, data: buf.findAll()});
});

exp.get("/timetable", (req, res) => {
	mogoConect((err, db) => {
		if (err) {
			console.error(`Unable to connect to the mongoDB server. Error:${err}`);
			res.json({e: true, msg: `Unable to connect to the mongoDB server. Error:${err}`});
			return;
		}
		
		var collection = db.collection('timetable');
					
		collection.find().toArray((err, doc) => {
			if (err) {
				res.json({e: true, msg: `mongodb error : ${err}`});
			} else {
				if (doc === null) {
					res.json({e: true, msg: "not found"});
				} else {
					res.json({e: false, data: doc});
				}
			}
			db.close();
		}); 
	});
	
});

exp.get("/timetable/:name", (req, res) => {
	var name = req.params.name;

	mogoConect((err, db) => {
		if (err) {
			console.error(`Unable to connect to the mongoDB server. Error:${err}`);
			res.json({e: true, msg: `Unable to connect to the mongoDB server. Error:${err}`});
			return;
		}
		
		var collection = db.collection('timetable');
					
		collection.findOne({name: name}, (err, doc) => {
			if (err) {
				res.json({e: true, msg: `mongodb error : ${err}`});
			} else {
				if (doc === null) {
					res.json({e: true, msg: "not found"});
				} else {
					res.json({e: false, data: doc});
				}
			}
			db.close();
		}); 
	}); 
});

server.listen(config.http.port, () => {
    console.info(`Starting http server on port ${config.http.port}`);
});

/*
io.on("connection", (socket) => {
	console.info(`New client connected (id=${socket.id}).`);
	socket.createTime = Math.floor(new Date().getTime() / 1000);
    _clients.push(socket);
	
	socket.on("track", function (data) {
		var index = clients.indexOf(socket);
		
	});
	
	socket.on("disconnect", function() {
        var index = clients.indexOf(socket);
        if (index != -1) {
            _clients = _clients.splice(index, -1);
            console.info(`Client gone (id=${socket.id}).`);
        }
    });
});
*/

net.createServer(function (socket) {
	socket.createTime = Math.floor(new Date().getTime() / 1000);
	socket.id = Math.floor(Math.random() * 1000);
	_clients.push(socket);
  
	socket.on("data", function (data) {
		var obj;
		try{
			obj = JSON.parse(data);
		} catch(e) {
			console.error(e);
			return;
		}
		var event = typeof obj === "undefined" ? "" : obj.event;
		var data = typeof obj === "undefined" ? "" : obj.data;
		// console.log(`event: ${event}, data: ${JSON.stringify(data)}`);
	});

	socket.on("end", function () {
		var index = _clients.indexOf(socket);
        if (index != -1) {
            _clients.splice(index, 1);
            // console.info(`Client gone (id=${socket.id}).`);
        }
	});
}).listen(config.tcp.port, () => {
	// console.info(`Starting tcp server on port ${config.tcp.port}`);
});

// Send a message to all clients
var broadcast = (event, data) => {
	var json = JSON.stringify({event: event, data: data});
	_clients.forEach((client) => {
		client.write(json);
	});
}

buf.onupdate = (data) => {
	mogoConect((err, db) => {
		if (err) {
			console.error(`Unable to connect to the mongoDB server. Error:${err}`);
			return;
		}
		
		var collection = db.collection('track');
				
		collection.findOne({imei: data.imei}, (err, doc) => {
			if (err) {
				console.error(`mongodb error : ${err}`);
			} else {
				broadcast(`BUS:${doc.name}`, data);
				/*for (var i=0;i<_clients.length;i++) {
					console.log(`Send : ${_clients[i].id}`);
					_clients[i].emit(`BUS:${doc.name}`, data);
					
				}*/
			}
			db.close();
		});
	});
};

var updateBuffer = () => {
	var all = buf.findAll();
	if (all.length > 0) {
		mogoConect((err, db) => {
			if (err) {
				console.error(`Unable to connect to the mongoDB server. Error:${err}`);
				res.json({e: true, msg: `Unable to connect to the mongoDB server. Error:${err}`});
				return;
			}
			
			var collection = db.collection('track');	
			
			var now = Math.floor(new Date().getTime() / 1000);
			for (var i=0;i<all.length;i++) {
				if ((now - all[i].update) > 90) {
					collection.updateOne({imei: all[i].imei}, {
						$set: { 
							latitude: all[i].latitude,
							longitude: all[i].longitude,
							speedkm: all[i].speedkm
						}
					});
					buf.Remove(i);
				}
			}
			db.close();
		});
	}
	// console.log("Run buffer update.");
	setTimeout(updateBuffer, 60000);
};
setTimeout(updateBuffer, 60000);

setInterval(() => {
	var now = Math.floor(new Date().getTime() / 1000);
	for (var i=0;i<_clients.length;i++) {
		if ((now - _clients[i].createTime) > 180) {
			_clients[i].destroy();
		}
	}
}, 1800000);
