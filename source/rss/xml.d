module rss.xml;
import std.xml;
import std.traits;
import std.range : ElementType;
import rss.attributes;


template xmlName(T...) if(T.length == 1) {
    static if(hasUDA!(T[0], XMLName))
        enum xmlName = getUDAs!(T[0], XMLName)[0].name;
    else
        enum xmlName = __traits(identifier, (T[0]));
}

/+
Decodes XML acording to the structure of the struct entered.
+/
T decodeXML(T)(string source) if(hasUDA!(T, XMLName))
{					
    auto doc = new DocumentParser(source);
    enum name = xmlName!(T);
    T t = T.init;
    decodeXMLNode!(T, name)(doc, t);
    return t;
}

private void decodeXMLNode(T, string name)(ElementParser parser, ref T value)
    if(is(T == struct))
{
    foreach(i, ref item; value.tupleof)
    {
        alias type = typeof(item);
        enum fieldName = xmlName!(T.tupleof[i]);
        parser.onStartTag[fieldName] = (ElementParser e)
        {
            decodeXMLNode!(type, fieldName)(e, item);
        };
    }
    parser.parse();
}

private void decodeXMLNode(T, string name)(ElementParser parser, ref T value)
  if(!is(T == string) && isArray!T)
{
    auto e = ElementType!(T).init;
    decodeXMLNode!(typeof(e), name)(parser, e);
    value ~= e;
}

private string stripHidingComments(string s)
{
	import std.array;
	s = s.replace("<![CDATA[", "");
	s = s.replace("]]>", "");
	return s;
}

private void decodeXMLNode(T, string name)(ElementParser parser, ref T value)
    if(is(T == string))
{
    import std.conv, std.string;
    parser.onEndTag[name] = (e)
    {
		value = e.text.stripHidingComments();
    };
    parser.parse();
}

private void decodeXMLNode(T, string name)(ElementParser parser, ref T value)
	if(isNumeric!T)
{
	import std.conv, std.string;
	parser.onEndTag[name] = (e)
	{
		value = e.text.strip.to!T;
	};
	parser.parse();
}