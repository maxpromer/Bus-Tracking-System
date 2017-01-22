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
    res.send('<h1>Hello, my name is Bus Tracking System</h1>');
});

var docs;

exp.get("/track", (req, res) => {
	mogoConect((err, db) => {
		if (err) {
			console.error(`Unable to connect to the mongoDB server. Error:${err}`);
			res.json({e: true, msg: `Unable to connect to the mongoDB server. Error:${err}`});
			return;
		}

		if (typeof req.query.place === "undefined") {
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
		} else if (typeof req.query.place !== "undefined") {
			var collection = db.collection('places');
			
			collection.findOne({name: req.query.place}, (err, docPlace) => {
				if (err) {
					res.json({e: true, msg: "mongodb error : " + err});
					db.close();
				} else {
					if (!docPlace) {
						res.json({e: true, msg: "ไม่พบสถานที่ที่ค้นหา"});
						db.close();
						return;
					}
					
					var collection = db.collection('busline');
					
					// ยังไม่สมบูรณ์
					collection.findOne({name: docPlace.busline[0]}, function (err, docBusline) {
						if (err) {
							res.json({e: true, msg: "mongodb error : " + err});
							db.close();
						} else {
							var location;
							if (typeof req.query.location !== "undefined") {
								location = {
									lat: req.query.location.split(",")[0],
									long: req.query.location.split(",")[1]
								};
							} else {
								var DistanceStart = DistanceByMakepoint(docBusline["make-point"], {lat: docPlace.latitude,long: docPlace.longitude}, {lat: docBusline.start[0][0], long: docBusline.start[0][1]});
								var DistanceEnd = DistanceByMakepoint(docBusline["make-point"], {lat: docPlace.latitude,long: docPlace.longitude}, {lat: docBusline.start[1][0], long: docBusline.start[1][1]});
								
								location = {
									lat: docBusline.start[(DistanceStart < DistanceEnd ? 0 : 1)][0],
									long: docBusline.start[(DistanceStart < DistanceEnd ? 0 : 1)][1]
								};
							}
					
							DistanceByMakepoint(docBusline["make-point"], {lat: docPlace.latitude,long: docPlace.longitude}, {lat: location.lat, long: location.long}, function(placeDistance, point) {
							
								var collection = db.collection('track');
								
								// ยังไม่สมบูรณ์
								collection.find({name: docPlace.busline[0], install: true}, {_id: 0, driver: 0, picture: 0, install: 0}).toArray(function (err, docs) {
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
												var buslineAll = [];
												for (var index=0;index<docs.length;index++) {
													if (docs[index].online) {
														var DistanceBusToStart1 = DistanceByMakepoint(docBusline["make-point"], {lat: point[0].lat,long: point[0].long}, {lat: docs[index].latitude, long: docs[index].longitude});
														var DistanceBusToStart2 = DistanceByMakepoint(docBusline["make-point"], {lat: point[0].lat,long: point[0].long}, {lat: docs[index].before[0].latitude, long: docs[index].before[0].longitude});
														
														// console.log(DistanceBusToStart1);
														// console.log(DistanceBusToStart2);
														
														if (DistanceBusToStart1 < DistanceBusToStart2 || DistanceBusToStart1 < 0.05) {
															buslineAll.push(docs[index]);
														}
													}
												}
												
												res.json({
													e: false, 
													data: {
														start: {
															lat: location.lat, 
															long: location.long
														},
														end: {
															lat: docPlace.latitude,
															long: docPlace.longitude
														},
														distance: placeDistance,
														point: point,
														busline: buslineAll
													}
												});
												db.close();
											}
										});
									}
									
								});
							
							
							
								
							});
						}
					});
					/*DistanceByMakepoint(db, doc.busline[0], {lat: doc.latitude, long: doc.longitude}, {lat: 0, long: 0}, (err, doc) => {
						if (err) {
							res.json({e: true, msg: "mongodb error : " + err});
						} else {
							res.json({e: false, data: docs});
							db.close();
						}
					});*/
				}
			});
		}
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

/*
function DistanceByMakepoint(db, busline, point, local, callback) {
	var collection = db.collection('busline');

	collection.findOne({name: busline}, (err, doc) => {
		if (err) {
			callback(err);
			return;
		}
		
		/*
		var makepointCenter = {lat: 0, long: 0};
		var minDistance = Math.pow(10, 12);
		for (index=0;index<doc['make-point'].length;index++) {
			var tmpDistance = getDistanceFromLatLonInKm(point.lat, point.long, doc['make-point'][index][0], doc['make-point'][index][1]);
			if (tmpDistance < minDistance) {
				makepointCenter = {
					lat: doc['make-point'][index][0], 
					long: doc['make-point'][index][1]
				};
				minDistance = tmpDistance;
			}
		}
		console.log(minDistance);
		console.log(makepointCenter);
		callback(false, {});
	});
	// point.lat
	// point.long 
}*/

function DistanceByMakepoint(point, start, end, callback) {
	// console.log(point);
	// console.log(start);
	// console.log(end);

	var makepointStart = {lat: 0, long: 0};
	var minDistanceStart = Math.pow(10, 12);
	var makepointEnd = {lat: 0, long: 0};
	var minDistanceEnd = Math.pow(10, 12);
	var indexStart = -1;
	var indexEnd = -1;
	for (index=0;index<point.length;index++) {
		var tmpDistance = getDistanceFromLatLonInKm(start.lat, start.long, point[index][0], point[index][1]);
		if (tmpDistance < minDistanceStart) {
			makepointStart = {
				lat: point[index][0], 
				long: point[index][1]
			};
			minDistanceStart = tmpDistance;
			indexStart = index;
		}
		
		var tmpDistance2 = getDistanceFromLatLonInKm(end.lat, end.long, point[index][0], point[index][1]);
		if (tmpDistance2 < minDistanceEnd) {
			makepointEnd = {
				lat: point[index][0], 
				long: point[index][1]
			};
			minDistanceEnd = tmpDistance2;
			indexEnd = index;
		}
	}
	
	// console.log(minDistanceStart);
	// console.log(makepointStart);
	// console.log(minDistanceEnd);
	// console.log(makepointEnd);
	// console.log(indexStart);
	// console.log(indexEnd);
	
	var pointDistance = [];
	var Distance = minDistanceStart;
	for (index=(indexStart < indexEnd ? indexStart : indexEnd);index<=(indexStart < indexEnd ? indexEnd : indexStart);index++) {
		Distance += getDistanceFromLatLonInKm(point[index][0], point[index][1], point[index<(indexStart < indexEnd ? indexEnd : indexStart) ? index+1 : index][0], point[index<(indexStart < indexEnd ? indexEnd : indexStart) ? index+1 : index][1]);
		pointDistance.push({
			lat: point[index][0], 
			long: point[index][1]
		});
	}
	Distance += minDistanceEnd;
	Distance = Distance.toFixed(2);
	// console.log("New Distance is " + Distance + " km.");
	// console.log("Old Distance is " + getDistanceFromLatLonInKm(start.lat, start.long, end.lat, end.long).toFixed(2) + " km.");
	
	if (typeof callback === "function") {
		var pointDistanceA = [];
		if (indexStart < indexEnd) {
			for (index=pointDistance.length-1;index>=0;index--) {
				pointDistanceA.push(pointDistance[index]);
			}
		} else {
			pointDistanceA = pointDistance;
		}
		callback(Distance, pointDistanceA);
	}
	return Distance;
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
						doc.direction = find.direction;
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
		
		collection.findOne({imei: req.params.imei}, (err, docTrack) => {
			if (err) {
				res.json({e: true, msg: `mongodb error : ${err}`});
			} else {	
				if (!docTrack) {
					res.json({e: true, msg: `not found imei : ${imei}`});
					db.close();
				} else {
					var collection = db.collection('busline');
					
					collection.findOne({name: docTrack.name}, (err, docBusline) => {
						if (err) {
							res.json({e: true, msg: `mongodb error : ${err}`});
						} else {
							var direction = 0;
							var find = buf.findByImei(req.params.imei);
							if (find !== false) {
								var DistanceStartNow = DistanceByMakepoint(docBusline["make-point"], {lat: post.lat,long: post.long}, {lat: docBusline.start[0][0], long: docBusline.start[0][1]});
								var DistanceStartLast = DistanceByMakepoint(docBusline["make-point"], {lat: find.latitude,long: find.longitude}, {lat: docBusline.start[0][0], long: docBusline.start[0][1]});
								
								var DistanceEndNow = DistanceByMakepoint(docBusline["make-point"], {lat: post.lat,long: post.long}, {lat: docBusline.start[1][0], long: docBusline.start[1][1]});
								
								if ((DistanceStartNow < 1 && find.direction == -1) || (DistanceStartNow < 2 && find.direction == -2)) {
									direction = -2;
								} else if ((DistanceEndNow < 1 && find.direction == 1) || (DistanceEndNow < 2 && find.direction == 2)) {
									direction = 2;
								} else {
									direction = (DistanceStartNow < DistanceStartLast) ? -1 : 1;
								}
							}
				
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
							
							buf.Update(imei, {
								lat: post.lat, 
								long: post.long, 
								speedkm: post.speedkm,
								direction: direction
							});
						}
					});
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

exp.get("/places", (req, res) => {
	mogoConect((err, db) => {
		if (err) {
			console.error(`Unable to connect to the mongoDB server. Error:${err}`);
			res.json({e: true, msg: `Unable to connect to the mongoDB server. Error:${err}`});
			return;
		}
		
		var collection = db.collection('places');

		collection.find(req.query, {_id: 0}).toArray(function (err, docs) {
			if (err) {
				res.json({e: true, msg: "mongodb error : " + err});
			} else {
				res.json({e: false, data: docs});
			}
			db.close();
		});
	});
});

exp.get("/busline", (req, res) => {
	mogoConect((err, db) => {
		if (err) {
			console.error(`Unable to connect to the mongoDB server. Error:${err}`);
			res.json({e: true, msg: `Unable to connect to the mongoDB server. Error:${err}`});
			return;
		}
		
		var collection = db.collection('busline');

		collection.findOne(req.query, {_id: 0}, (err, doc) => {
			if (err) {
				res.json({e: true, msg: "mongodb error : " + err});
			} else {
				res.json({e: false, data: doc});
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
//	mogoConect((err, db) => {
//		if (err) {
//			console.error(`Unable to connect to the mongoDB server. Error:${err}`);
//			return;
//		}
//		
//		var collection = db.collection('track');
//				
//		collection.findOne({imei: data.imei}, (err, doc) => {
//			if (err) {
//				console.error(`mongodb error : ${err}`);
//			} else {
				broadcast('UPDATE', data);
				/*for (var i=0;i<_clients.length;i++) {
					console.log(`Send : ${_clients[i].id}`);
					_clients[i].emit(`BUS:${doc.name}`, data);
					
				}*/
//			}
//			db.close();
//		});
//	});
};

buf.onupdate = (data) => {
//	mogoConect((err, db) => {
//		if (err) {
//			console.error(`Unable to connect to the mongoDB server. Error:${err}`);
//			return;
//		}
//		
//		var collection = db.collection('track');
//				
//		collection.findOne({imei: data.imei}, (err, doc) => {
//			if (err) {
//				console.error(`mongodb error : ${err}`);
//			} else {
				broadcast('REMOVE', data);
				/*for (var i=0;i<_clients.length;i++) {
					console.log(`Send : ${_clients[i].id}`);
					_clients[i].emit(`BUS:${doc.name}`, data);
					
				}*/
//			}
//			db.close();
//		});
//	});
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
							speedkm: all[i].speedkm,
							direction: all[i].direction
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


function getDistanceFromLatLonInKm(lat1,lon1,lat2,lon2) {
  var R = 6371; // Radius of the earth in km
  var dLat = deg2rad(lat2-lat1);  // deg2rad below
  var dLon = deg2rad(lon2-lon1); 
  var a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * 
    Math.sin(dLon/2) * Math.sin(dLon/2)
    ; 
  var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
  var d = R * c; // Distance in km
  return d;
}

function deg2rad(deg) {
  return deg * (Math.PI/180)
}