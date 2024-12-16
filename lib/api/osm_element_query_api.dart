import 'package:flutter_map/flutter_map.dart';
import 'package:osm_api/osm_api.dart';


/// This class exposes API calls for querying [OSMElement]s via the OSM API.

class OSMElementQueryAPI {
  final OSMAPI _osmApi;

  OSMElementQueryAPI({
    String endPoint = 'https://api.openstreetmap.org/api/0.6',
  }) :
    _osmApi = OSMAPI(
      baseUrl: endPoint,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    );


  /// Method to query all OSM elements from a specific bbox via OSM API.
  /// All direct sub elements of relations are also queried if the total member count
  /// of the relation doesn't exceed the defined [relationMemberLimit].
  /// This limit exists to prevent querying overly large relations, such as country boundaries.
  /// This method will throw [OSMAPI] connection errors.

  Future<OSMElementBundle> queryByBBox(LatLngBounds bbox, { int relationMemberLimit = 50 }) async {
    final bboxElementBundle = await _osmApi.getElementsByBoundingBox(
      BoundingBox(
        bbox.west, bbox.south, bbox.east, bbox.north
      )
    );
    // query all direct relation elements with less than X members
    final relations = bboxElementBundle.relations.where(
      (relation) => relation.members.length <= relationMemberLimit,
    );
    final relationsElementBundle = await _getElementsFromRelations(relations);

    return bboxElementBundle.merge(relationsElementBundle);
  }


  /// Query all elements of the supplied relations and merge them to a single [OSMElementBundle].

  Future<OSMElementBundle> _getElementsFromRelations(Iterable<OSMRelation> relations) {
    // query all direct relation elements (nodes, ways and relations) + nodes of ways
    final queries = relations.map(
      (relation) => _osmApi.getFullRelation(relation.id),
    );
    // merge all relation element bundles
    return Stream.fromFutures(queries).fold(
      OSMElementBundle(),
      (previous, elementBundle) => previous.merge(elementBundle),
    );
  }


  /// A method to terminate the api client and cleanup any open connections.
  /// This should be called inside the widgets dispose callback.

  void dispose() {
    _osmApi.dispose();
  }
}
