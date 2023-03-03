import 'package:latlong2/latlong.dart';

import '/models/element_variants/base_element.dart';
import '/models/question_catalog/question_catalog.dart';

abstract class ElementFilter {
  Iterable<ProcessedElement> filter(Iterable<ProcessedElement> elements);
}


/// Filter for elements which geometric center is inside the given [Circle].

class AreaFilter implements ElementFilter {
  final Circle _area;

  AreaFilter({
    required Circle area,
  }) : _area = area;

  @override
  Iterable<ProcessedElement> filter(Iterable<ProcessedElement> elements) => elements.where(
    (element) => _area.isPointInside(element.geometry.center)
  );
}


/// Filter for elements which match at least one question from a given [QuestionCatalog].

class QuestionFilter implements ElementFilter {
  final QuestionCatalog _questionCatalog;

  QuestionFilter({
    required QuestionCatalog questionCatalog,
  }) : _questionCatalog = questionCatalog;

  @override
  Iterable<ProcessedElement> filter(Iterable<ProcessedElement> elements) => elements.where(_matches);

  bool _matches(ProcessedElement element) {
    return _questionCatalog.any((question) {
      return question.conditions.any((condition) {
        return condition.matches(element);
      });
    });
  }
}
