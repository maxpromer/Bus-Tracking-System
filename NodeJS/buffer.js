var _buffer = [];

exports.onupdate = null;

exports.Add = (imei, location) => {
	if (typeof imei !== "string") 
		return false;
	if (typeof location !== "object") 
		return false;
	if (typeof location.lat !== "number") 
		return false;
	if (typeof location.long !== "number") 
		return false;
	if (typeof location.speedkm !== "number") 
		location.speedkm = 0;
	if (typeof location.direction!== "number") 
		location.direction = 0;
	
	var latitude = location.lat;
	var longitude = location.long;
	var speedkm = location.speedkm
	var direction = location.direction
	
	var find = exports.findByImei(imei, true);
	if (find === false) {
		_buffer.push({		
			imei: imei, 
			latitude: latitude, 
			longitude: longitude,
			speedkm: speedkm,
			direction: direction,
			update: Math.floor(new Date().getTime() / 1000)
		});
	} else {
		exports.Update(imei, { 
			latitude: latitude, 
			longitude: longitude,
			speedkm: speedkm,
			direction: direction
		});
	}
	return true;
};

exports.Update = (imei, location) => {
	if (typeof imei !== "string") 
		return false;
	if (typeof location !== "object") 
		return false;
	if (typeof location.lat !== "number") 
		return false;
	if (typeof location.long !== "number") 
		return false;
	if (typeof location.speedkm !== "number") 
		location.speedkm = 0;
	if (typeof location.direction!== "number") 
		location.direction = 0;
	
	var find = exports.findByImei(imei, true);
	if (find === false) {
		exports.Add(imei, location);
	} else {
		_buffer[find].latitude = location.lat;
		_buffer[find].longitude = location.long;
		_buffer[find].speedkm = location.speedkm;
		_buffer[find].direction = location.direction;
		_buffer[find].update = Math.floor(new Date().getTime() / 1000);
	}
	if (typeof exports.onupdate === "function") 
		exports.onupdate({imei: imei, location: location});
	
	return true;
};

exports.Remove = (index) => {
	if (typeof exports.onremove === "function") 
		exports.onremove(_buffer[index]);
	_buffer = _buffer.splice(index, -1);
	return true;
}

exports.RemoveByImei = (imei) => {
	var find = exports.findByImei(imei, true);
	if (find !== false) {
		exports.Remove(find);
	}
	return true;
}
exports.findAll = () => _buffer;

exports.findByImei = (imei, index) => {
	if (typeof index !== "boolean") index = false;
	
    for (var i = 0; i < _buffer.length; i++) {
        if (_buffer[i].imei == imei) return index ? i : _buffer[i];
    }
	return false
};