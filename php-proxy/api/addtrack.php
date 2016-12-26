<?Php
header('Content-Type: application/json');
$imei = $_GET['imei'];
$latitude = $_GET['latitude'];
$longitude = $_GET['longitude'];
$speedkm = (isset($_GET['speedkm']) && is_numeric($_GET['speedkm'])) ? $_GET['speedkm'] : 0;
$verify = $_GET['verify'];

if (!is_numeric($latitude))
	ExitJson('{"e": true, "msg": "latitude not valid"}');
if (!is_numeric($longitude))
	ExitJson('{"e": true, "msg": "longitude not valid"}');
if ($verify != <Can not be revealed>)
	ExitJson('{"e": true, "msg": "verify is fail"}');
	
$url = "http://bsv.host-1gb.com:85/track/{$imei}";
$data = json_encode(array('lat' => (double)$latitude, 'long' => (double)$longitude, 'speedkm' => (double)$speedkm));

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_HEADER, false);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_CONNECTTIMEOUT ,0); 
curl_setopt($ch, CURLOPT_TIMEOUT, 10); //timeout in seconds
curl_setopt($ch, CURLOPT_HTTPHEADER, array('Content-Type: application/json','Content-Length: ' . strlen($data)));

$response = curl_exec($ch);
$curl_errno = curl_errno($ch);
$curl_error = curl_error($ch);
if ($curl_errno > 0) 
	ExitJson('{"e": true, "msg": "connect to server fail."}');

exit($response);

function ExitJson($str) {
	header('Content-length: ' . strlen($str));
	exit($str);
}