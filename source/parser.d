import std.regex;
import std.string;
import tokenspec;
import token;
import lexer;
import astobjs;

class Parser
{
  Token[] tokensToParse;
  JMain main;
  this(Lexer lxr)
  {
    tokensToParse = lxr.tokens();
    main = new JMain(parse());
  }

  auto getMain()
  {
    return main;
  }

  AstNode[] parse()
  {
    AstNode[] objects = [];

    while (tokensToParse.length != 0)
    {
      if (tokensToParse[0].type() == TokenEnum.DECIMAL_LITERAL)
      {
        objects ~= new JDecimal(tokensToParse[0].value());
        tokensToParse = tokensToParse[1..$];
        continue;
      }

      if (tokensToParse[0].type() == TokenEnum.STRING_LITERAL)
      {
        objects ~= new JString(tokensToParse[0].value()[1..$-1]);
        tokensToParse = tokensToParse[1..$];
        continue;
      }
      //Path
      if (tokensToParse[0].type() == TokenEnum.PATH_NODE)
      {
        objects ~= new JPath(tokensToParse[0].value);
        tokensToParse = tokensToParse[1..$];
        continue;
      }

      //Function call
      if (tokensToParse[0].type() == TokenEnum.IDENTIFIER)
      {
        auto function_name = tokensToParse[0].value();
        tokensToParse = tokensToParse[1..$];

        auto subexpression = parse();
        objects ~= new JFunctionCall(function_name, subexpression);
        continue;
      }

      if (tokensToParse[0].type() == TokenEnum.CALL_TERMINATOR)
      {
        tokensToParse = tokensToParse[1..$];
        return objects;
      }
    }
    return objects;
  }
}
