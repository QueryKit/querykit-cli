// This is a generated file from QueryKit.
// https://github.com/QueryKit/querykit-cli

import QueryKit

/// Extension to {{ className }} providing an QueryKit attribute descriptions.
extension {{ className }} {{ "{" }}{% for attribute in attributes %}
  static var {{ attribute.name }}:Attribute<{{ attribute.type }}> { return Attribute("{{ attribute.name }}") }{% endfor %}

  {% if not isAbstract %}
  @objc class func queryset(context:NSManagedObjectContext) -> QuerySet<{{ className }}> {
    return QuerySet(context, "{{ entityName }}")
  }
  {% endif %}
}

extension Attribute where AttributeType: {{ className }} {{ "{" }}{% for attribute in attributes %}
  var {{ attribute.name }}:Attribute<{{ attribute.type }}> { return attribute(AttributeType.{{ attribute.name }}) }{% endfor %}
}

