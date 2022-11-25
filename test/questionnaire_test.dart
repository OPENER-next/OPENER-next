import 'package:flutter_test/flutter_test.dart';
import 'package:open_stop/models/answer.dart';
import 'package:open_stop/models/osm_condition.dart';
import 'package:open_stop/models/question_catalog/answer_constructor.dart';
import 'package:open_stop/models/question_catalog/answer_definition.dart';
import 'package:open_stop/models/question_catalog/question_catalog.dart';
import 'package:open_stop/models/question_catalog/question_definition.dart';
import 'package:open_stop/models/questionnaire.dart';
import 'package:osm_api/osm_api.dart';

void main() async {

  const stringAnswer = StringAnswerDefinition(
    input: StringInputDefinition(),
    constructor: AnswerConstructor({ 'tag_a': [r'$input'] }),
  );

  const dummyCatalog = QuestionCatalog([
    QuestionDefinition(id: 0, name: 'q1', question: 'q1', isProfessional: false,
      conditions: [
        OsmCondition({ 'tag_a': false }, [])
      ],
      answer: stringAnswer,
    ),
    QuestionDefinition(id: 0, name: 'q2', question: 'q2', isProfessional: false,
      conditions: [
        OsmCondition({ 'tag_a': '1' }, [])
      ],
      answer: stringAnswer,
    ),
    QuestionDefinition(id: 0, name: 'q2', question: 'q2', isProfessional: false,
      conditions: [
        OsmCondition({ 'tag_a': '2' }, [])
      ],
      answer: stringAnswer,
    ),
  ]);


  test('test if succeeding questions get correctly removed when pre-condition changes', () {
    final element = OSMNode(0, 0, tags: {
      'other_tag': 'val',
    });

    final questionnaire = Questionnaire(osmElement: element, questionCatalog: dummyCatalog);

    expect(questionnaire.length, equals(1));
    expect(questionnaire.activeIndex, equals(0));
    expect(questionnaire.workingElement.tags, equals({ 'other_tag': 'val' }));

    questionnaire.update(const StringAnswer(definition: stringAnswer, value: '1'));
    questionnaire.next();

    expect(questionnaire.length, equals(2));
    expect(questionnaire.activeIndex, equals(1));
    expect(questionnaire.workingElement.tags, equals({ 'other_tag': 'val', 'tag_a': '1' }));

    questionnaire.update(const StringAnswer(definition: stringAnswer, value: '2'));
    questionnaire.next();

    expect(questionnaire.length, equals(3));
    expect(questionnaire.activeIndex, equals(2));
    expect(questionnaire.workingElement.tags, equals({ 'other_tag': 'val', 'tag_a': '2' }));

    questionnaire.jumpTo(0);

    expect(questionnaire.length, equals(3));
    expect(questionnaire.activeIndex, equals(0));
    expect(questionnaire.workingElement.tags, equals({ 'other_tag': 'val', 'tag_a': '2' }));

    questionnaire.update(const StringAnswer(definition: stringAnswer, value: 'OTHER'));

    expect(questionnaire.length, equals(1));
    expect(questionnaire.activeIndex, equals(0));
    expect(questionnaire.workingElement.tags, equals({ 'other_tag': 'val', 'tag_a': 'OTHER' }));

    expect(questionnaire.next(), isFalse);
  });
}