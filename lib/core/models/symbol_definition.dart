enum SymbolKind {
  function,
  clazz,
  component,
  route,
  variable,
  interfaceOrType,
  importExport,
}

class SymbolDefinition {
  final String name;
  final SymbolKind kind;
  final String relativeFilePath;
  final int lineNumber;
  final String signature;
  final String? documentation;

  const SymbolDefinition({
    required this.name,
    required this.kind,
    required this.relativeFilePath,
    required this.lineNumber,
    required this.signature,
    this.documentation,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'kind': kind.name,
        'relativeFilePath': relativeFilePath,
        'lineNumber': lineNumber,
        'signature': signature,
        'documentation': documentation,
      };

  factory SymbolDefinition.fromJson(Map<String, dynamic> json) =>
      SymbolDefinition(
        name: json['name'] as String,
        kind: SymbolKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => SymbolKind.function,
        ),
        relativeFilePath: json['relativeFilePath'] as String,
        lineNumber: json['lineNumber'] as int,
        signature: json['signature'] as String,
        documentation: json['documentation'] as String?,
      );
}
