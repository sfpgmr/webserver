{

  class Node {
    constructor(name,attributes,content){
      name && (this.name = name);
      attributes && (this.attributes = attributes);
      content && (this.content = content);
    }
  }

  class HtmlNode extends Node {
    constructor(name,attributes,content){
      super(name,attributes,content);
    }
  }
 
  function reduceToObj (xs)
  {
    let attr = {};
    for(const x of xs){
      if(x && x.name){
        attr[x.name] = x.text;
      }
    }
    return attr;
  }
}

start = title:Title __ metadata:MetaData aditionalStyle:(__ s:AditionalStyle {return s})? body:BODY {
  return {
    title:title.content,
    metadata:metadata,
    aditionalStyle:aditionalStyle,
    body:body
  };
}

// ブログのタイトル
Title "title" = "#" _ title:$([^\r\n]*) [\r]?[\n] { return new Node('title',null,title)}

// 更新日などのメタデータが入る
MetaData "metadata" = metastart:('<script'i _ 'type="application/json"'i _ 'id="sfblog"'i _ ">")? __ '{' __ json:(ch:(!('</script'i  __ '>') c:. { return c })* { return ch.join('') }) __ '}' __ metaend:('</script'i    __ '>')? {
  if(!!metastart != !!metaend) {
    error('<script> tag unmatch');
  }
  return JSON.parse(json);
}

AditionalStyle = "<style>" __ style:(ch:(!('</style'i  __ '>') c:. { return c })* { return ch.join('') }) __ '</style>' {return style;}

BODY 'body' = ( __ / CustomTag / MarkDown / HTML )*

CustomTag = '[' Symbol ':' ']'

/****************************************************
* HTML parser
*****************************************************/

/**
 * HTMLDocument is just a collection of elements.
 */
HtmlDocument = __ nodes:Element* { return nodes; }

/**
 * Elements - https://www.w3.org/TR/html5/syntax.html#elements-0
 */
Element  = RawText / Nested / Void / Comment / DocType / Text

RawText  = Script / Style / Textarea / Title / PlainText

Script    "script"    = '<script'i    attrs:Attributes '>' __ content:(ch:(!('</script'i    __ '>') c:. { return c })* { return ch.join('') }) __ '</script'i    __ '>' __ { return new HtmlNode('script', attrs, content); }
Style     "style"     = '<style'i     attrs:Attributes '>' __ content:(ch:(!('</style'i     __ '>') c:. { return c })* { return ch.join('') }) __ '</style'i     __ '>' __ { return new HtmlNode('style', attrs, content); }
Textarea  "textarea"  = '<textarea'i  attrs:Attributes '>' __ content:(ch:(!('</textarea'i  __ '>') c:. { return c })* { return ch.join('') }) __ '</textarea'i  __ '>' __ { return new HtmlNode('textarea', attrs, content); }
Title     "title"     = '<title'i     attrs:Attributes '>' __ content:(ch:(!('</title'i     __ '>') c:. { return c })* { return ch.join('') }) __ '</title'i     __ '>' __ { return new HtmlNode('title', attrs, content); }
PlainText "plaintext" = '<plaintext'i attrs:Attributes '>' __ content:(ch:(!('</plaintext'i __ '>') c:. { return c })* { return ch.join('') }) __ '</plaintext'i __ '>' __ { return new HtmlNode('plaintext', attrs, content); }

Nested    "element"   = begin:TagBegin __ content:Element* __ end:TagEnd __ &{ return begin.name == end } {
  begin.content = content;
  return begin;
}

TagBegin  "begin tag" = '<'  name:Symbol attrs:Attributes? '>' { return new HtmlNode(name.toLowerCase(), attrs); }
TagEnd    "end tag"   = '</' name:Symbol __               '>' { return name.toLowerCase(); }

/**
 * Void element (with self closing tag, w/o content)
 * - 'area'i / 'base'i / 'br'i / 'col'i / 'embed'i / 'hr'i / 'img'i / 'input'i / 'keygen'i / 'link'i / 'meta'i / 'param'i / 'source'i / 'track'i / 'wbr'i
 */
Void      "element"   = '<' name:Symbol attrs:Attributes ('/>' / '>') __ { return new HtmlNode(name, attrs); }

Comment   "comment"   = '<!--' text:CommentText '-->' __ {
    return new HtmlNode('comment', null, text);
  }

CommentText = ch:(!'-->' c:. { return c; })* { return ch.join('') }

DocType   "doctype"   = '<!DOCTYPE'i __ root:Symbol __ type:('public'i / 'system'i)? __ text:String* '>' __ {
    const node = new HtmlNode('doctype');
    node.root = root && root.toLowerCase();
    node.type = type && type.toLowerCase();
    //node.content = content && content.toLowerCase();
    return node;
  }

Text "text"
  = ch:(c:[^<] { return c })+ {
    return new HtmlNode('text', null,ch.join(''));
  }
  / ch:(!TagEnd !Void !Comment !DocType c:. { c })+ {
    return new HtmlNode('text', null, ch.join(''));
  }

/**
 * Element attributes
 */
Attributes = __ attrs:Attribute* __ { return (attrs && attrs.length) ? reduceToObj(attrs) : null;}

Attribute "attribute"
  = name:Symbol __ text:(__ '=' __ s:String { return s })? __ { return {name:name, text:text}; }
  / !'/>' [^> ]+ __ { return null; }

/**
 * String - single, double, w/o quotes
 */
String "string"
  = '"'  ch:[^"]*      '"'  __ { return ch.join(''); }
  / '\'' ch:[^']*      '\'' __ { return ch.join(''); }
  /      ch:[^"'<>` ]+      __ { return ch.join(''); }

/**
 * Tag name, attribute name
 */
Symbol = h:[a-zA-Z0-9_\-] t:[a-zA-Z0-9:_\-]* { return h + t.join('') }

__ "space characters"
  = [\r\n \t\u000C]*

_ "space characters without cr,lf"
  = [ \t\u000c]*
