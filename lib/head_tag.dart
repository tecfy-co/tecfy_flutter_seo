abstract class HeadTag {
  const HeadTag();
}

class MetaTag extends HeadTag {
  final String? name;
  final String? httpEquiv;
  final String? content;
  final String propKey;
  final String propContent;

  const MetaTag({
    this.name,
    this.httpEquiv,
    this.content,
    this.propKey = "name",
    this.propContent = "content",
  });
}

class LinkTag extends HeadTag {
  final String? title;
  final String? rel;
  final String? type;
  final String? href;
  final String? media;

  const LinkTag({
    this.title,
    this.rel,
    this.type,
    this.href,
    this.media,
  });
}

class ScriptTag extends HeadTag {
  final String? type;
  final String? body;
  const ScriptTag({
    this.type,
    this.body,
  });
}
