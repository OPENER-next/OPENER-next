import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_stop/models/element_processing/element_processor.dart';
import 'package:open_stop/models/element_variants/base_element.dart';
import 'package:open_stop/models/geographic_geometries.dart';
import 'package:osm_api/osm_api.dart';

void main() async {
  // taken from https://api.openstreetmap.org/api/0.6/way/30779889/full.json
  // view here: https://www.openstreetmap.org/way/30779889
  const way01 = '{"version":"0.6","generator":"CGImap 0.8.6 (407022 spike-07.openstreetmap.org)","copyright":"OpenStreetMap and contributors","attribution":"http://www.openstreetmap.org/copyright","license":"http://opendatacommons.org/licenses/odbl/1-0/","elements":[{"type":"node","id":340375856,"lat":50.8139380,"lon":12.9314887,"timestamp":"2010-06-13T16:13:54Z","version":2,"changeset":4980090,"user":"mpeter89","uid":59991},{"type":"node","id":340375857,"lat":50.8142772,"lon":12.9308588,"timestamp":"2010-06-13T16:13:54Z","version":2,"changeset":4980090,"user":"mpeter89","uid":59991},{"type":"node","id":340375858,"lat":50.8143749,"lon":12.9309906,"timestamp":"2010-06-13T16:13:44Z","version":2,"changeset":4980090,"user":"mpeter89","uid":59991},{"type":"node","id":340375859,"lat":50.8140357,"lon":12.9316204,"timestamp":"2010-06-13T16:13:54Z","version":2,"changeset":4980090,"user":"mpeter89","uid":59991},{"type":"node","id":340375860,"lat":50.8143480,"lon":12.9310404,"timestamp":"2010-06-13T16:13:54Z","version":2,"changeset":4980090,"user":"mpeter89","uid":59991},{"type":"node","id":340375871,"lat":50.8142668,"lon":12.9311902,"timestamp":"2020-09-19T13:41:35Z","version":3,"changeset":91150503,"user":"wielandb","uid":11695431},{"type":"node","id":340375888,"lat":50.8140740,"lon":12.9312390,"timestamp":"2016-11-24T22:43:15Z","version":9,"changeset":43933448,"user":"phoo","uid":36934,"tags":{"entrance":"yes","wheelchair":"no"}},{"type":"node","id":1467270538,"lat":50.8141598,"lon":12.9313901,"timestamp":"2013-03-03T10:25:41Z","version":4,"changeset":15231759,"user":"Klumbumbus","uid":550300,"tags":{"entrance":"yes","wheelchair":"yes"}},{"type":"node","id":7914473786,"lat":50.8140871,"lon":12.9312144,"timestamp":"2020-09-16T22:52:14Z","version":1,"changeset":91009916,"user":"wielandb","uid":11695431},{"type":"node","id":7914473787,"lat":50.8140657,"lon":12.9312542,"timestamp":"2020-09-16T22:52:14Z","version":1,"changeset":91009916,"user":"wielandb","uid":11695431},{"type":"node","id":7923010320,"lat":50.8143531,"lon":12.9309611,"timestamp":"2020-09-19T13:41:35Z","version":1,"changeset":91150503,"user":"wielandb","uid":11695431,"tags":{"access":"permit","door":"double","entrance":"secondary","level":"0","wheelchair":"yes"}},{"type":"way","id":30779889,"timestamp":"2021-07-24T12:46:18Z","version":11,"changeset":108531246,"user":"fghj753","uid":10394095,"nodes":[340375856,7914473787,340375888,7914473786,340375857,7923010320,340375858,340375860,340375871,1467270538,340375859,340375856],"tags":{"addr:city":"Chemnitz","addr:country":"DE","addr:housenumber":"3","addr:postcode":"09126","addr:street":"Thüringer Weg","building":"dormitory","building:colour":"#dcdcdc","building:levels":"5","building:use":"??","name":"Studentenwerk Chemnitz-Zwickau","roof:colour":"#f08080","roof:levels":"1","roof:material":"roof_tiles","roof:orientation":"along","roof:shape":"hipped"}}]}';

  // taken from https://api.openstreetmap.org/api/0.6/relation/73027/full.json
  // view here: https://www.openstreetmap.org/relation/73027
  const relation01 = '{"version":"0.6","generator":"CGImap 0.8.6 (733186 spike-08.openstreetmap.org)","copyright":"OpenStreetMap and contributors","attribution":"http://www.openstreetmap.org/copyright","license":"http://opendatacommons.org/licenses/odbl/1-0/","elements":[{"type":"node","id":271326678,"lat":50.8154477,"lon":12.9261230,"timestamp":"2020-02-19T14:15:55Z","version":9,"changeset":81225690,"user":"shogun","uid":94315},{"type":"node","id":340010590,"lat":50.8150696,"lon":12.9261452,"timestamp":"2020-02-19T14:15:55Z","version":4,"changeset":81225690,"user":"shogun","uid":94315},{"type":"node","id":340010598,"lat":50.8150341,"lon":12.9246274,"timestamp":"2020-02-19T14:15:55Z","version":4,"changeset":81225690,"user":"shogun","uid":94315},{"type":"node","id":340010604,"lat":50.8154122,"lon":12.9246053,"timestamp":"2020-02-19T14:15:55Z","version":4,"changeset":81225690,"user":"shogun","uid":94315},{"type":"node","id":340010609,"lat":50.8151448,"lon":12.9259259,"timestamp":"2020-02-19T14:15:55Z","version":5,"changeset":81225690,"user":"shogun","uid":94315},{"type":"node","id":340010615,"lat":50.8152727,"lon":12.9259212,"timestamp":"2020-02-19T14:15:55Z","version":5,"changeset":81225690,"user":"shogun","uid":94315},{"type":"node","id":340010619,"lat":50.8152703,"lon":12.9257547,"timestamp":"2020-02-19T14:15:55Z","version":5,"changeset":81225690,"user":"shogun","uid":94315},{"type":"node","id":340010625,"lat":50.8151423,"lon":12.9257594,"timestamp":"2020-02-19T14:15:55Z","version":5,"changeset":81225690,"user":"shogun","uid":94315},{"type":"node","id":340010630,"lat":50.8151280,"lon":12.9255614,"timestamp":"2020-02-19T14:15:55Z","version":5,"changeset":81225690,"user":"shogun","uid":94315},{"type":"node","id":340010634,"lat":50.8151152,"lon":12.9250114,"timestamp":"2020-02-19T14:15:55Z","version":5,"changeset":81225690,"user":"shogun","uid":94315},{"type":"node","id":340010635,"lat":50.8152965,"lon":12.9250008,"timestamp":"2020-02-19T14:15:55Z","version":5,"changeset":81225690,"user":"shogun","uid":94315},{"type":"node","id":340010637,"lat":50.8153094,"lon":12.9255508,"timestamp":"2020-02-19T14:15:55Z","version":5,"changeset":81225690,"user":"shogun","uid":94315},{"type":"node","id":2133977386,"lat":50.8152519,"lon":12.9261345,"timestamp":"2020-02-19T14:15:55Z","version":2,"changeset":81225690,"user":"shogun","uid":94315,"tags":{"entrance":"main"}},{"type":"node","id":2397232453,"lat":50.8152831,"lon":12.9255524,"timestamp":"2020-02-19T14:15:55Z","version":2,"changeset":81225690,"user":"shogun","uid":94315},{"type":"node","id":2397232455,"lat":50.8152966,"lon":12.9261319,"timestamp":"2020-02-19T14:15:55Z","version":2,"changeset":81225690,"user":"shogun","uid":94315},{"type":"node","id":2397232458,"lat":50.8154341,"lon":12.9255435,"timestamp":"2020-02-19T14:15:55Z","version":2,"changeset":81225690,"user":"shogun","uid":94315},{"type":"way","id":30742868,"timestamp":"2013-07-26T11:53:11Z","version":4,"changeset":17100678,"user":"vsandre","uid":69628,"nodes":[340010590,340010598,340010604,2397232458,271326678,2397232455,2133977386,340010590]},{"type":"way","id":30742869,"timestamp":"2009-02-02T13:22:28Z","version":1,"changeset":81079,"user":"vsandre","uid":69628,"nodes":[340010609,340010615,340010619,340010625,340010609]},{"type":"way","id":30742870,"timestamp":"2013-07-26T11:53:11Z","version":2,"changeset":17100678,"user":"vsandre","uid":69628,"nodes":[340010630,2397232453,340010637,340010635,340010634,340010630]},{"type":"relation","id":73027,"timestamp":"2021-07-12T11:41:37Z","version":11,"changeset":107832730,"user":"Mephist0pheles","uid":1544983,"members":[{"type":"way","ref":30742868,"role":"outer"},{"type":"way","ref":30742869,"role":"inner"},{"type":"way","ref":30742870,"role":"inner"}],"tags":{"addr:housename":"C60 Physikbau","building":"university","building:colour":"49484e","building:levels":"2","building:material":"concrete","name":"Physikgebäude","ref":"2/P","roof:shape":"flat","type":"multipolygon"}}]}';

  // taken from https://api.openstreetmap.org/api/0.6/relation/1373368/full.json
  // view here: https://www.openstreetmap.org/relation/1373368
  const relation02 = '{"version":"0.6","generator":"CGImap 0.8.6 (1404994 spike-07.openstreetmap.org)","copyright":"OpenStreetMap and contributors","attribution":"http://www.openstreetmap.org/copyright","license":"http://opendatacommons.org/licenses/odbl/1-0/","elements":[{"type":"node","id":219072420,"lat":50.8250337,"lon":12.8962694,"timestamp":"2010-11-25T10:10:26Z","version":2,"changeset":6453304,"user":"brandus","uid":78983},{"type":"node","id":219072421,"lat":50.8244085,"lon":12.8928649,"timestamp":"2011-01-12T23:23:28Z","version":3,"changeset":6952949,"user":"brandus","uid":78983},{"type":"node","id":219072426,"lat":50.8260565,"lon":12.8944023,"timestamp":"2011-02-27T13:09:22Z","version":5,"changeset":7410442,"user":"PeterSchum","uid":344598},{"type":"node","id":691611088,"lat":50.8258008,"lon":12.8922629,"timestamp":"2010-04-10T15:58:51Z","version":1,"changeset":4383882,"user":"Joerg Fischer","uid":7186},{"type":"node","id":691611105,"lat":50.8260201,"lon":12.8932297,"timestamp":"2010-12-23T15:44:00Z","version":2,"changeset":6746482,"user":"pucko","uid":77102},{"type":"node","id":691611109,"lat":50.8260322,"lon":12.8955526,"timestamp":"2011-01-12T23:23:29Z","version":2,"changeset":6952949,"user":"brandus","uid":78983},{"type":"node","id":1100843585,"lat":50.8260499,"lon":12.8946509,"timestamp":"2011-01-12T23:23:24Z","version":1,"changeset":6952949,"user":"brandus","uid":78983,"tags":{"barrier":"gate","bicycle":"yes","foot":"yes","motorcar":"yes"}},{"type":"node","id":1100843588,"lat":50.8249250,"lon":12.8956773,"timestamp":"2011-01-12T23:23:24Z","version":1,"changeset":6952949,"user":"brandus","uid":78983,"tags":{"barrier":"gate","bicycle":"yes","foot":"yes","motorcar":"yes"}},{"type":"node","id":1100843611,"lat":50.8256884,"lon":12.8957832,"timestamp":"2011-01-12T23:23:24Z","version":1,"changeset":6952949,"user":"brandus","uid":78983,"tags":{"barrier":"gate","bicycle":"yes","foot":"yes"}},{"type":"node","id":4389101140,"lat":50.8245542,"lon":12.8928021,"timestamp":"2016-09-07T11:09:06Z","version":1,"changeset":41976737,"user":"Klumbumbus","uid":550300},{"type":"node","id":4389101142,"lat":50.8247325,"lon":12.8927249,"timestamp":"2016-09-07T11:09:06Z","version":1,"changeset":41976737,"user":"Klumbumbus","uid":550300},{"type":"node","id":8022079527,"lat":50.8248337,"lon":12.8951801,"timestamp":"2020-10-19T13:25:40Z","version":1,"changeset":92712308,"user":"wermak","uid":11211647},{"type":"way","id":94833445,"timestamp":"2016-09-07T11:09:06Z","version":2,"changeset":41976737,"user":"Klumbumbus","uid":550300,"nodes":[691611105,691611088,4389101142,4389101140,219072421],"tags":{"barrier":"wall","source":"Yahoo aerial imagery"}},{"type":"way","id":94833456,"timestamp":"2020-10-19T13:25:40Z","version":3,"changeset":92712308,"user":"wermak","uid":11211647,"nodes":[691611105,219072426,1100843585,691611109,1100843611,219072420,1100843588,8022079527,219072421],"tags":{"barrier":"wall","name":"St. Nikolai","name:de":"St. Nikolai"}},{"type":"relation","id":1373368,"timestamp":"2014-12-18T01:33:10Z","version":2,"changeset":27542629,"user":"Klumbumbus","uid":550300,"members":[{"type":"way","ref":94833456,"role":"outer"},{"type":"way","ref":94833445,"role":"outer"}],"tags":{"landuse":"cemetery","type":"multipolygon"}}]}';

  // taken from https://api.openstreetmap.org/api/0.6/relation/3577671/full.json
  // view here: https://www.openstreetmap.org/relation/3577671
  const relation03 = '{"version":"0.6","generator":"CGImap 0.8.6 (1427577 spike-07.openstreetmap.org)","copyright":"OpenStreetMap and contributors","attribution":"http://www.openstreetmap.org/copyright","license":"http://opendatacommons.org/licenses/odbl/1-0/","elements":[{"type":"node","id":692162380,"lat":51.0386551,"lon":13.7367058,"timestamp":"2015-11-27T01:29:32Z","version":8,"changeset":35603771,"user":"Wolle DD","uid":1161559},{"type":"node","id":692162388,"lat":51.0391425,"lon":13.7337439,"timestamp":"2015-11-27T01:29:33Z","version":6,"changeset":35603771,"user":"Wolle DD","uid":1161559},{"type":"node","id":692162390,"lat":51.0389392,"lon":13.7346779,"timestamp":"2015-11-27T01:29:32Z","version":8,"changeset":35603771,"user":"Wolle DD","uid":1161559},{"type":"node","id":692162411,"lat":51.0395427,"lon":13.7327313,"timestamp":"2015-06-19T22:18:15Z","version":5,"changeset":32085648,"user":"Kakaner","uid":1851521},{"type":"node","id":692162422,"lat":51.0386132,"lon":13.7366871,"timestamp":"2015-11-27T01:29:32Z","version":7,"changeset":35603771,"user":"Wolle DD","uid":1161559},{"type":"node","id":692162443,"lat":51.0392290,"lon":13.7338095,"timestamp":"2014-03-15T09:41:19Z","version":3,"changeset":21113611,"user":"Wolle DD","uid":1161559},{"type":"node","id":692162452,"lat":51.0388430,"lon":13.7351962,"timestamp":"2015-11-27T01:29:32Z","version":9,"changeset":35603771,"user":"Wolle DD","uid":1161559},{"type":"node","id":692162460,"lat":51.0406056,"lon":13.7294767,"timestamp":"2015-11-27T01:29:33Z","version":6,"changeset":35603771,"user":"Wolle DD","uid":1161559},{"type":"node","id":692162464,"lat":51.0389097,"lon":13.7352349,"timestamp":"2015-08-26T18:44:14Z","version":7,"changeset":33603345,"user":"Kakaner","uid":1851521},{"type":"node","id":692162481,"lat":51.0390129,"lon":13.7347196,"timestamp":"2015-08-26T18:37:03Z","version":7,"changeset":33603179,"user":"Kakaner","uid":1851521},{"type":"node","id":692162489,"lat":51.0405454,"lon":13.7294276,"timestamp":"2015-11-27T01:29:33Z","version":7,"changeset":35603771,"user":"Wolle DD","uid":1161559},{"type":"node","id":968918894,"lat":51.0387439,"lon":13.7362517,"timestamp":"2015-11-27T01:29:32Z","version":7,"changeset":35603771,"user":"Wolle DD","uid":1161559},{"type":"node","id":988900760,"lat":51.0399311,"lon":13.7314145,"timestamp":"2016-06-28T12:28:02Z","version":10,"changeset":40342543,"user":"MENTZ_TU","uid":2385132,"tags":{"level":"1"}},{"type":"node","id":997588860,"lat":51.0396588,"lon":13.7322456,"timestamp":"2016-06-28T12:28:02Z","version":9,"changeset":40342543,"user":"MENTZ_TU","uid":2385132,"tags":{"level":"1"}},{"type":"node","id":1364180373,"lat":51.0388210,"lon":13.7357426,"timestamp":"2015-11-27T01:29:32Z","version":5,"changeset":35603771,"user":"Wolle DD","uid":1161559},{"type":"node","id":1485537370,"lat":51.0387003,"lon":13.7364847,"timestamp":"2015-06-19T22:18:09Z","version":5,"changeset":32085648,"user":"Kakaner","uid":1851521},{"type":"node","id":1485537375,"lat":51.0387483,"lon":13.7357858,"timestamp":"2015-11-27T01:29:32Z","version":5,"changeset":35603771,"user":"Wolle DD","uid":1161559},{"type":"node","id":1501721260,"lat":51.0392284,"lon":13.7334438,"timestamp":"2015-11-27T01:29:33Z","version":5,"changeset":35603771,"user":"Wolle DD","uid":1161559},{"type":"node","id":1639455492,"lat":51.0391320,"lon":13.7339882,"timestamp":"2017-01-25T15:36:27Z","version":4,"changeset":45479692,"user":"haytigran","uid":360562,"tags":{"level":"1"}},{"type":"node","id":2718674769,"lat":51.0391836,"lon":13.7335968,"timestamp":"2015-11-27T01:29:33Z","version":3,"changeset":35603771,"user":"Wolle DD","uid":1161559},{"type":"node","id":2718674772,"lat":51.0393013,"lon":13.7335343,"timestamp":"2014-03-15T09:41:18Z","version":1,"changeset":21113611,"user":"Wolle DD","uid":1161559},{"type":"node","id":2718674774,"lat":51.0393859,"lon":13.7332310,"timestamp":"2015-06-19T22:18:13Z","version":2,"changeset":32085648,"user":"Kakaner","uid":1851521},{"type":"node","id":2718674776,"lat":51.0393055,"lon":13.7331858,"timestamp":"2015-11-27T01:29:33Z","version":4,"changeset":35603771,"user":"Wolle DD","uid":1161559},{"type":"node","id":2718674778,"lat":51.0390317,"lon":13.7342179,"timestamp":"2015-11-27T01:29:32Z","version":2,"changeset":35603771,"user":"Wolle DD","uid":1161559},{"type":"node","id":3547628374,"lat":51.0390878,"lon":13.7339600,"timestamp":"2017-01-25T15:36:28Z","version":4,"changeset":45479692,"user":"haytigran","uid":360562},{"type":"node","id":3547628375,"lat":51.0391797,"lon":13.7340186,"timestamp":"2017-01-25T15:36:28Z","version":2,"changeset":45479692,"user":"haytigran","uid":360562},{"type":"node","id":3581332806,"lat":51.0388634,"lon":13.7354887,"timestamp":"2015-08-26T18:44:14Z","version":2,"changeset":33603345,"user":"Kakaner","uid":1851521},{"type":"node","id":3586101998,"lat":51.0404632,"lon":13.7296611,"timestamp":"2015-11-27T01:29:33Z","version":3,"changeset":35603771,"user":"Wolle DD","uid":1161559},{"type":"node","id":3606015347,"lat":51.0386808,"lon":13.7362353,"timestamp":"2015-11-27T01:29:32Z","version":2,"changeset":35603771,"user":"Wolle DD","uid":1161559},{"type":"node","id":3606015348,"lat":51.0387938,"lon":13.7354916,"timestamp":"2015-11-27T01:29:32Z","version":3,"changeset":35603771,"user":"Wolle DD","uid":1161559},{"type":"node","id":3606101855,"lat":51.0402734,"lon":13.7303675,"timestamp":"2017-01-19T10:24:26Z","version":5,"changeset":45293708,"user":"haytigran","uid":360562,"tags":{"level":"1"}},{"type":"node","id":3715805171,"lat":51.0388878,"lon":13.7349417,"timestamp":"2015-11-27T01:29:32Z","version":2,"changeset":35603771,"user":"Wolle DD","uid":1161559},{"type":"node","id":3715805176,"lat":51.0395358,"lon":13.7325510,"timestamp":"2016-01-10T12:26:24Z","version":6,"changeset":36481693,"user":"ubahnverleih","uid":114388},{"type":"node","id":3715805177,"lat":51.0395715,"lon":13.7325802,"timestamp":"2016-01-10T12:26:24Z","version":6,"changeset":36481693,"user":"ubahnverleih","uid":114388},{"type":"node","id":3715805178,"lat":51.0395684,"lon":13.7324524,"timestamp":"2016-01-10T12:26:24Z","version":6,"changeset":36481693,"user":"ubahnverleih","uid":114388},{"type":"node","id":3715805180,"lat":51.0396032,"lon":13.7324806,"timestamp":"2016-01-10T12:26:24Z","version":6,"changeset":36481693,"user":"ubahnverleih","uid":114388},{"type":"node","id":3715805182,"lat":51.0399137,"lon":13.7314003,"timestamp":"2016-06-28T12:28:00Z","version":6,"changeset":40342543,"user":"MENTZ_TU","uid":2385132},{"type":"node","id":3715805184,"lat":51.0399487,"lon":13.7314290,"timestamp":"2016-06-28T12:28:00Z","version":6,"changeset":40342543,"user":"MENTZ_TU","uid":2385132},{"type":"node","id":3715808841,"lat":51.0389547,"lon":13.7350059,"timestamp":"2015-08-26T18:44:11Z","version":1,"changeset":33603345,"user":"Kakaner","uid":1851521},{"type":"node","id":3727833195,"lat":51.0395831,"lon":13.7324077,"timestamp":"2016-06-28T12:28:00Z","version":6,"changeset":40342543,"user":"MENTZ_TU","uid":2385132},{"type":"node","id":3727833196,"lat":51.0396176,"lon":13.7324366,"timestamp":"2016-06-28T12:28:00Z","version":6,"changeset":40342543,"user":"MENTZ_TU","uid":2385132},{"type":"node","id":3727833197,"lat":51.0396415,"lon":13.7322311,"timestamp":"2016-06-28T12:28:00Z","version":5,"changeset":40342543,"user":"MENTZ_TU","uid":2385132},{"type":"node","id":3727833198,"lat":51.0396760,"lon":13.7322600,"timestamp":"2016-06-28T12:28:00Z","version":5,"changeset":40342543,"user":"MENTZ_TU","uid":2385132},{"type":"node","id":3729994671,"lat":51.0398088,"lon":13.7317125,"timestamp":"2016-01-12T21:21:03Z","version":7,"changeset":36538706,"user":"ubahnverleih","uid":114388},{"type":"node","id":3729994672,"lat":51.0398476,"lon":13.7317445,"timestamp":"2016-01-12T21:21:03Z","version":7,"changeset":36538706,"user":"ubahnverleih","uid":114388},{"type":"node","id":3729994673,"lat":51.0398406,"lon":13.7316161,"timestamp":"2016-01-12T21:21:03Z","version":7,"changeset":36538706,"user":"ubahnverleih","uid":114388},{"type":"node","id":3729994674,"lat":51.0398795,"lon":13.7316478,"timestamp":"2016-01-12T21:21:03Z","version":7,"changeset":36538706,"user":"ubahnverleih","uid":114388},{"type":"node","id":3768291536,"lat":51.0395550,"lon":13.7326938,"timestamp":"2015-10-02T01:12:10Z","version":1,"changeset":34380203,"user":"Wolle DD","uid":1161559},{"type":"node","id":3768291537,"lat":51.0394868,"lon":13.7326371,"timestamp":"2015-11-27T01:29:33Z","version":2,"changeset":35603771,"user":"Wolle DD","uid":1161559},{"type":"node","id":3768291544,"lat":51.0402881,"lon":13.7303798,"timestamp":"2017-01-19T10:24:26Z","version":3,"changeset":45293708,"user":"haytigran","uid":360562},{"type":"node","id":3768291545,"lat":51.0403355,"lon":13.7302370,"timestamp":"2017-01-19T10:24:26Z","version":3,"changeset":45293708,"user":"haytigran","uid":360562},{"type":"node","id":3768291546,"lat":51.0403062,"lon":13.7302124,"timestamp":"2017-01-19T10:24:26Z","version":3,"changeset":45293708,"user":"haytigran","uid":360562},{"type":"node","id":3768291547,"lat":51.0402588,"lon":13.7303553,"timestamp":"2017-01-19T10:24:26Z","version":3,"changeset":45293708,"user":"haytigran","uid":360562},{"type":"node","id":3937546375,"lat":51.0395419,"lon":13.7325560,"timestamp":"2016-01-10T12:26:20Z","version":1,"changeset":36481693,"user":"ubahnverleih","uid":114388},{"type":"node","id":3937546377,"lat":51.0395628,"lon":13.7325729,"timestamp":"2016-01-10T12:26:20Z","version":1,"changeset":36481693,"user":"ubahnverleih","uid":114388},{"type":"node","id":4269758612,"lat":51.0396246,"lon":13.7322171,"timestamp":"2016-06-28T12:27:56Z","version":1,"changeset":40342543,"user":"MENTZ_TU","uid":2385132},{"type":"node","id":4269758613,"lat":51.0396922,"lon":13.7322736,"timestamp":"2016-06-28T12:27:56Z","version":1,"changeset":40342543,"user":"MENTZ_TU","uid":2385132},{"type":"node","id":4269758614,"lat":51.0398971,"lon":13.7313867,"timestamp":"2016-06-28T12:27:56Z","version":1,"changeset":40342543,"user":"MENTZ_TU","uid":2385132},{"type":"node","id":4269758615,"lat":51.0399640,"lon":13.7314415,"timestamp":"2016-06-28T12:27:56Z","version":1,"changeset":40342543,"user":"MENTZ_TU","uid":2385132},{"type":"node","id":4269758618,"lat":51.0402405,"lon":13.7303399,"timestamp":"2017-01-19T10:24:27Z","version":2,"changeset":45293708,"user":"haytigran","uid":360562},{"type":"node","id":4269758619,"lat":51.0403058,"lon":13.7303947,"timestamp":"2017-01-19T10:24:27Z","version":2,"changeset":45293708,"user":"haytigran","uid":360562},{"type":"node","id":4401249456,"lat":51.0398741,"lon":13.7315910,"timestamp":"2016-09-14T14:34:39Z","version":1,"changeset":42151359,"user":"haytigran","uid":360562,"tags":{"level":"0"}},{"type":"node","id":4618078164,"lat":51.0398567,"lon":13.7315765,"timestamp":"2017-01-19T10:24:24Z","version":1,"changeset":45293708,"user":"haytigran","uid":360562},{"type":"node","id":4618078165,"lat":51.0398915,"lon":13.7316052,"timestamp":"2017-01-19T10:24:24Z","version":1,"changeset":45293708,"user":"haytigran","uid":360562},{"type":"node","id":4632284519,"lat":51.0391188,"lon":13.7339798,"timestamp":"2017-01-25T15:36:27Z","version":1,"changeset":45479692,"user":"haytigran","uid":360562},{"type":"node","id":4632284520,"lat":51.0391462,"lon":13.7339972,"timestamp":"2017-01-25T15:36:27Z","version":1,"changeset":45479692,"user":"haytigran","uid":360562},{"type":"node","id":4632284521,"lat":51.0391827,"lon":13.7338506,"timestamp":"2017-01-25T15:36:27Z","version":1,"changeset":45479692,"user":"haytigran","uid":360562},{"type":"node","id":4632284522,"lat":51.0391553,"lon":13.7338331,"timestamp":"2017-01-25T15:36:27Z","version":1,"changeset":45479692,"user":"haytigran","uid":360562},{"type":"way","id":85944999,"timestamp":"2017-12-21T15:32:08Z","version":13,"changeset":54817768,"user":"Nakaner","uid":496201,"nodes":[692162489,692162460]},{"type":"way","id":85945031,"timestamp":"2019-03-22T14:13:35Z","version":22,"changeset":68412971,"user":"RailAir","uid":1977785,"nodes":[692162460,4269758619,4269758615,4269758613,3768291536,692162411,2718674774,2718674772,692162443],"tags":{"description":"Dresden Hbf, Bahnsteig 2","height":"0.55","layer":"1","level":"1","railway":"platform_edge","ref":"2"}},{"type":"way","id":266282258,"timestamp":"2019-03-22T14:13:35Z","version":17,"changeset":68412971,"user":"RailAir","uid":1977785,"nodes":[692162388,2718674769,1501721260,2718674776,3768291537,4269758612,4269758614,4269758618,3586101998,692162489],"tags":{"description":"Dresden Hbf, Bahnsteig 1","height":"0.55","layer":"1","level":"1","railway":"platform_edge","ref":"1"}},{"type":"way","id":266289058,"timestamp":"2017-12-21T15:32:09Z","version":14,"changeset":54817768,"user":"Nakaner","uid":496201,"nodes":[692162422,3606015347,1485537375,3606015348,692162452,3715805171,692162390,2718674778,3547628374,692162388],"tags":{"description":"Dresden Hbf, Bahnsteig 1a","height":"0.55","level":"1","railway":"platform_edge","ref":"1a"}},{"type":"way","id":266289059,"timestamp":"2017-12-21T15:32:09Z","version":5,"changeset":54817768,"user":"Nakaner","uid":496201,"nodes":[692162380,692162422]},{"type":"way","id":266289062,"timestamp":"2017-12-21T15:32:09Z","version":14,"changeset":54817768,"user":"Nakaner","uid":496201,"nodes":[692162443,3547628375,692162481,3715808841,692162464,3581332806,1364180373,968918894,1485537370,692162380],"tags":{"description":"Dresden Hbf, Bahnsteig 2a","height":"0.55","level":"1","railway":"platform_edge","ref":"2a"}},{"type":"way","id":367687786,"timestamp":"2016-01-10T12:26:22Z","version":4,"changeset":36481693,"user":"ubahnverleih","uid":114388,"nodes":[3715805177,3715805180,3715805178,3715805176,3937546375,3937546377,3715805177]},{"type":"way","id":367687787,"timestamp":"2017-01-19T10:24:32Z","version":7,"changeset":45293708,"user":"haytigran","uid":360562,"nodes":[4618078164,4401249456,4618078165,3715805184,988900760,3715805182,4618078164],"tags":{"level":"0;1","room":"stairs"}},{"type":"way","id":368946513,"timestamp":"2017-04-01T20:29:39Z","version":4,"changeset":47366812,"user":"letihu","uid":1787357,"nodes":[3727833196,3727833198,997588860,3727833197,3727833195,3727833196],"tags":{"level":"0;1","room":"stairs"}},{"type":"way","id":369188497,"timestamp":"2015-11-26T19:44:03Z","version":3,"changeset":35598895,"user":"Nakaner-repair","uid":2149259,"nodes":[3729994672,3729994674,3729994673,3729994671,3729994672]},{"type":"way","id":373350138,"timestamp":"2016-01-11T21:23:03Z","version":3,"changeset":36513614,"user":"ubahnverleih","uid":114388,"nodes":[3606101855,3768291544,3768291545,3768291546,3768291547,3606101855],"tags":{"level":"0;1","room":"stairs"}},{"type":"way","id":468757462,"timestamp":"2017-01-25T15:36:27Z","version":1,"changeset":45479692,"user":"haytigran","uid":360562,"nodes":[4632284522,4632284521,4632284520,1639455492,4632284519,4632284522]},{"type":"relation","id":3577671,"timestamp":"2020-10-04T21:29:45Z","version":14,"changeset":91946815,"user":"Osmosefixer2021","uid":10820890,"members":[{"type":"way","ref":85944999,"role":"outer"},{"type":"way","ref":85945031,"role":"outer"},{"type":"way","ref":266289062,"role":"outer"},{"type":"way","ref":266289059,"role":"outer"},{"type":"way","ref":266289058,"role":"outer"},{"type":"way","ref":266282258,"role":"outer"},{"type":"way","ref":367687786,"role":"inner"},{"type":"way","ref":367687787,"role":"inner"},{"type":"way","ref":368946513,"role":"inner"},{"type":"way","ref":369188497,"role":"inner"},{"type":"way","ref":373350138,"role":"inner"},{"type":"way","ref":468757462,"role":"inner"}],"tags":{"area":"yes","foot":"yes","layer":"1","level":"1","lit":"yes","public_transport":"platform","railway":"platform","ref":"1;2","shelter":"yes","surface":"concrete","tactile_paving":"yes","train":"yes","type":"multipolygon","wheelchair":"yes"}}]}';

  test('test if a geometric osm element is successfully created from a given way', () {
    final bundle = _parse(way01);
    // create processed element
    final elementProcessor = OSMElementProcessor(bundle);
    final procEle = elementProcessor.elements.whereType<ProcessedWay>().first;

    expect(
      procEle.geometry,
      isInstanceOf<GeographicPolygon>()
    );

    expect(
      (procEle.geometry as GeographicPolygon).hasNoHoles,
      isTrue
    );

    expect(
      (procEle.geometry as GeographicPolygon).outerShape.isClosed,
      isTrue
    );

    expect(
      (procEle.geometry as GeographicPolygon).outerShape.isClosed,
      isTrue
    );
  });


  test('test if a geometric osm element is successfully created from a given relation1', () {
    final bundle = _parse(relation01);
    // create processed element
    final elementProcessor = OSMElementProcessor(bundle);
    final procEle = elementProcessor.elements.whereType<ProcessedRelation>().first;

    expect(
      procEle.geometry,
      isInstanceOf<GeographicPolygon>()
    );

    final poly = procEle.geometry as GeographicPolygon;

    expect(
      poly.hasHoles,
      isTrue
    );

    expect(
      poly.innerShapes,
      hasLength(2)
    );

    final polyWithoutHoles = GeographicPolygon(outerShape: poly.outerShape);

    expect(
      polyWithoutHoles.enclosesPolyline(poly.innerShapes.first),
      isTrue
    );

    expect(
      polyWithoutHoles.enclosesPolyline(poly.innerShapes.last),
      isTrue
    );

    const pointInsidePolygon = GeographicPoint(LatLng(50.81519, 12.92478));
    const pointOnPolygonEdge = GeographicPoint(LatLng(50.8152519, 12.9261345));
    const pointOutsidePolygon = GeographicPoint(LatLng(50.8152072, 12.9262028));
    const pointInsideHole = GeographicPoint(LatLng(50.81523, 12.92523));

    expect(
      poly.enclosesPoint(pointInsidePolygon),
      isTrue
    );

    expect(
      poly.enclosesPoint(pointOnPolygonEdge),
      isFalse
    );

    expect(
      poly.enclosesPoint(pointOutsidePolygon),
      isFalse
    );

    expect(
      poly.enclosesPoint(pointInsideHole),
      isFalse
    );
  });



  test('test if a geometric osm element is successfully created from a given relation2', () {
    final bundle = _parse(relation02);
    // create processed element
    final elementProcessor = OSMElementProcessor(bundle);
    final procEle = elementProcessor.elements.whereType<ProcessedRelation>().first;

    expect(
      procEle.geometry,
      isInstanceOf<GeographicPolygon>()
    );

    final poly = procEle.geometry as GeographicPolygon;

    expect(
      poly.hasNoHoles,
      isTrue
    );

    const pointInsidePolygon = GeographicPoint(LatLng(50.82547, 12.89363));
    const pointOnPolygonEdge = GeographicPoint(LatLng(50.8256884, 12.8957832));
    const pointOutsidePolygon = GeographicPoint(LatLng(50.82604, 12.89144));

    expect(
      poly.enclosesPoint(pointInsidePolygon),
      isTrue
    );

    expect(
      poly.enclosesPoint(pointOnPolygonEdge),
      isFalse
    );

    expect(
      poly.enclosesPoint(pointOutsidePolygon),
      isFalse
    );
  });


  test('test if a geometric osm element is successfully created from a given relation3', () {
    final bundle = _parse(relation03);
    // create processed element
    final elementProcessor = OSMElementProcessor(bundle);
    final procEle = elementProcessor.elements.whereType<ProcessedRelation>().first;

    expect(
      procEle.geometry,
      isInstanceOf<GeographicPolygon>()
    );

    final poly = procEle.geometry as GeographicPolygon;

    expect(
      poly.hasHoles,
      isTrue
    );

    expect(
      poly.innerShapes,
      hasLength(6)
    );

    const pointInsidePolygon = GeographicPoint(LatLng(51.0391, 13.73419));
    const pointOnPolygonEdge = GeographicPoint(LatLng(51.0405454, 13.7294276));
    const pointOutsidePolygon = GeographicPoint(LatLng(51.03921, 13.73212));

    expect(
      poly.enclosesPoint(pointInsidePolygon),
      isTrue
    );

    expect(
      poly.enclosesPoint(pointOnPolygonEdge),
      isFalse
    );

    expect(
      poly.enclosesPoint(pointOutsidePolygon),
      isFalse
    );

    const pathInside = GeographicPolyline([LatLng(51.0401503, 13.7307434), LatLng(51.0400668, 13.7310070)]);
    const pathOutside = GeographicPolyline([LatLng(51.04014, 13.72976), LatLng(51.04005, 13.7301)]);
    const pathThroughHole = GeographicPolyline([LatLng(51.0401503, 13.7307434), LatLng(51.0398141, 13.7318035)]);

    expect(
      poly.enclosesPolyline(pathInside),
      isTrue
    );

    expect(
      poly.enclosesPolyline(pathOutside),
      isFalse
    );

    expect(
      poly.enclosesPolyline(pathThroughHole),
      isFalse
    );
  });
}


OSMElementBundle _parse(String jsonString) {
  // parse json
  final jsonData = json.decode(jsonString) as Map<String, dynamic>;
  // get all elements
  final jsonObjects = (jsonData['elements'] as List<dynamic>).cast<Map<String, dynamic>>();

  return OSMElementBundle.fromElements(_lazyJSONtoOSMElements(jsonObjects));
}


Iterable<OSMElement> _lazyJSONtoOSMElements(Iterable<Map<String, dynamic>> objects) sync* {
  for (final jsonObj in objects) {
    switch (jsonObj['type']) {
      case 'node':
        yield OSMNode.fromJSONObject(jsonObj);

      case 'way':
        yield OSMWay.fromJSONObject(jsonObj);

      case 'relation':
        yield OSMRelation.fromJSONObject(jsonObj);
    }
  }
}
