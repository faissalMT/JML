import std.stdio;
import std.json;
import std.string;
import std.conv;
import std.variant;
import std.array;
import std.algorithm;

enum AstNodeType
{
  FUNCTION_CALL,
  STRING_LITERAL,
  PATH,
  ARGUMENT_LIST,
  DECIMAL_LITERAL
}

interface AstNode
{
  Variant run(JSONValue *data);
}

static pure auto getFunctions()
{
    Variant function(JSONValue*, Variant[] ...)[string] funcs = [
      "sum": function (data, args...) {
        return Variant(reduce!((accumulator, i) => accumulator.coerce!(real) + i.coerce!(real))(Variant(0), args));
      },
      "get": function (data, args...) {
        return (*data).get(args[0].coerce!JSONPath);
      },
      "set": function (data, args...) {
        data.set(args[0].coerce!(JSONPath), args[1]);
        return Variant(null);
      },
      "product": function (data, args...) {
        return Variant(reduce!((accumulator, i) => accumulator.coerce!(real) * i.coerce!(real))(Variant(1), args));
      },
      "Array": function (data, args...) {
        return Variant(args);
      },
      "strcat": function (data, args...) {
        return Variant(reduce!((accumulator, i) => accumulator.coerce!(string) ~ i.coerce!(string))(Variant(""), args));
      },
      "arraycat": function (data, args...) {
        return Variant(reduce!((accumulator, i) => accumulator.get!(Variant[]) ~ i.get!(Variant[]))(Variant(cast(Variant[])[]), args));
      },
      "PRINT": function (data, args...) {
        foreach (arg; args)
        {
          writeln(arg.coerce!string);
        }

        return Variant(null);
      },
      "TYPE": function (data, args...) {
        return Variant(args[0].type().to!string);
      },
      "and": function (data, args...) {
        return Variant(reduce!((accumulator, i) => accumulator.coerce!(bool) & i.coerce!(bool))(Variant(true), args));
      },
      "or": function (data, args...) {
        return Variant(reduce!((accumulator, i) => accumulator.coerce!(bool) | i.coerce!(bool))(Variant(false), args));
      }
    ];
    return funcs;
}

class JFunctionCall : AstNode
{
  Variant function(JSONValue*, Variant[] ...) func;
  string function_name;
  AstNode[] arguments;

  this(string function_name, AstNode[] arguments)
  {
    this.func = getFunctions()[function_name];
    this.function_name = function_name;
    this.arguments = arguments;
  }

  Variant run(JSONValue *data)
  {
    Variant[] evaluated_args = map!(arg => arg.run(data))(arguments).array();
    return func(data, evaluated_args);
  }
}

class JString : AstNode
{
  string value;
  this(string value)
  {
    this.value = value;
  }

  Variant run(JSONValue *data)
  {
    return Variant(value);
  }

  unittest
  {
    import std.json;
    assert((new JString("Hello")).run(new JSONValue()).get!(string) == "Hello");
  }
}

class JDecimal : AstNode
{
  //Switch to std.decimal when it's added
  //For now use real cus it's the best we've got
  real value;

  this(string value)
  {
    this.value = value.to!real;
  }

  Variant run(JSONValue *data)
  {
    return Variant(value);
  }

  unittest
  {
    import std.json;
    assert((new JDecimal("1")).run(new JSONValue()).get!(real) == 1);
  }
}

class JSONPath
{
  string[] path;
  this(string path)
  {
    this.path = path.split("/")[1..$-1];
  }

  string[] getPath()
  {
    return path;
  }

  unittest
  {
    assert((new JSONPath("/")).getPath() == []);
    assert((new JSONPath("/short/")).getPath() == ["short"]);
    assert((new JSONPath("/a/very/long/path/")).getPath() == ["a", "very", "long", "path"]);
  }
}

Variant get(JSONValue data, JSONPath path)
{
  auto nextNode(JSONValue data, string node) {
    switch (data.type())
    {
      case JSONType.array:
        return data[node.to!int];
      case JSONType.object:
        return data[node];
      default:
        return JSONValue(null);
    }
  }

  JSONValue value;
  try
  {
    value = reduce!(nextNode)(data, path.getPath());
  }
  catch (JSONException e)
  {
    return Variant(null);
  }

  Variant jsonValueToVariant(JSONValue value)
  {
    switch (value.type())
    {
      case JSONType.null_:
        return Variant(null);

      case JSONType.integer:
        return Variant(value.integer.to!real);
      case JSONType.float_:
        return Variant(value.floating.to!real);

      case JSONType.true_:
      case JSONType.false_:
        return Variant(value.boolean);

      case JSONType.string:
        return Variant(value.str);

      case JSONType.array:
        return Variant(map!(i => jsonValueToVariant(i))(value.array).array());

      default:
        return Variant(value);
    }
  }

  return jsonValueToVariant(value);
}

unittest
{
  auto json = parseJSON(`{"some": {"data": 1 }}`);
  assert(json.get((new JSONPath("/some/data/"))).get!(real) == 1);
  assert(json.get((new JSONPath("/some/data/that/doesnt/exist"))).peek!(real) is null);
}

void set(JSONValue *data, JSONPath path, Variant value)
{
  auto nextNode(JSONValue *data, string node) {
    try
    {
      switch (data.type())
      {
        case JSONType.array:
          return &(*data)[node.to!int];
        case JSONType.object:
          return &(*data)[node];
        default:
          return &(*data)[node];
      }
    }
    catch (JSONException e)
    {
      switch (data.type())
      {
        case JSONType.array:
          (*data).array ~= JSONValue();
          return &(*data)[(*data).array.length-1];

        case JSONType.object:
          (*data)[node] = parseJSON("{}");
          return &(*data)[node];

        default:
          return &(*data)[node];
      }
    }
  }

  JSONValue* jsonToChange = reduce!(nextNode)(data, path.getPath());
  JSONValue getJSONValueForType(T)(Variant value) {
    if (value.type() == typeid(T))
    {
       return JSONValue(value.get!T);
    }
    return JSONValue(null);
  }

  JSONValue variantToJsonValue(Variant value)
  {
    auto returnval = getJSONValueForType!(real)(value);
    if (returnval.type() != JSONType.null_)
    {
      return returnval;
    }

    returnval = getJSONValueForType!(string)(value);
    if (returnval.type() != JSONType.null_)
    {
      return returnval;
    }

    returnval = getJSONValueForType!(bool)(value);
    if (returnval.type() != JSONType.null_)
    {
      return returnval;
    }

    returnval = getJSONValueForType!(JSONValue)(value);
    if (returnval.type() != JSONType.null_)
    {
      return returnval;
    }

    if (value.type() == typeid(Variant[]))
    {
      return JSONValue(map!(i => variantToJsonValue(i))(value.get!(Variant[])).array());
    }
    return value.get!JSONValue;
  }
  *jsonToChange = variantToJsonValue(value);
}

class JPath : AstNode
{
  JSONPath path;

  this(string path)
  {
    this.path = new JSONPath(path);
  }

  Variant run(JSONValue *data)
  {
    return Variant(path);
  }
}

class JMain : AstNode
{
  AstNode[] objects;
  this(AstNode[] objects)
  {
    this.objects = objects;
  }

  Variant run(JSONValue *data)
  {
    foreach (object; objects)
    {
      object.run(data);
    }
    writeln(*data);
    return Variant(data);
  }
}
