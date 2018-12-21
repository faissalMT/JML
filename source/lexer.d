import tokenspec;
import token;
import std.regex;
import std.stdio;

pure tokenRegex(alias rx, alias additionalFlags = "")() {
  //writeln(rx);
  return ctRegex!(`^` ~ rx, "x"~additionalFlags);
}

class Lexer
{

  string toParse;
  Token[] parsed;
  TokenSpec[] parseSpec;

  this(string toParse)
  {
    this.toParse = toParse;
    this.parsed = [];
    parseSpec = [
      new TokenSpec(tokenRegex!(`#.*$`, "m"), TokenEnum.WHITESPACE), //comments
      new TokenSpec(tokenRegex!(`\;`), TokenEnum.CALL_TERMINATOR),
      new TokenSpec(tokenRegex!(`(?:''|(?<!\\)(?:\\{2})*'(?:(?<!\\)(?:\\{2})*\\'|[^'])+(?<!\\)(?:\\{2})*')`), TokenEnum.STRING_LITERAL),
      new TokenSpec(tokenRegex!(`\s+`), TokenEnum.WHITESPACE),
      new TokenSpec(tokenRegex!(`[A-Za-z]+`), TokenEnum.IDENTIFIER),
      new TokenSpec(tokenRegex!(`[0-9]+(?:\.[0-9]+)?`), TokenEnum.DECIMAL_LITERAL),
      new TokenSpec(tokenRegex!(`(?:(?:/[A-z0-9]+)+/|/)`), TokenEnum.PATH_NODE)
    ];
    lex();
  }

  auto lex()
  {
    while (this.toParse.length != 0)
    {
      auto priorLength = this.toParse.length;
      foreach (TokenSpec spec; parseSpec)
      {
        consume(spec);
      }

      if (priorLength == this.toParse.length)
      {
        writeln("Invalid Syntax");
        break;
      }
    }
  }

  auto tokens()
  {
    return parsed;
  }

  auto consume(TokenSpec spec)
  {
    auto callback(Captures!string capture)
    {
      if (!spec.ignore())
      {
        parsed ~= new Token(spec, capture.hit);
      }
      return "";
    }

    this.toParse = this.toParse.replaceFirst!(callback)(spec.regex);
  }

  void toString(scope void delegate(const(char)[]) sink) {
    foreach (token; parsed)
    {
      sink("["~token.toString()~"]");
    }
  }
}
