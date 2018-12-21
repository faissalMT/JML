import std.regex;

enum TokenEnum
{
  CALL_TERMINATOR,
  IDENTIFIER,
  DECIMAL_LITERAL,
  WHITESPACE,
  PATH_NODE,
  STRING_LITERAL,
  ARGUMENT_DELIMITER
}

class TokenSpec
{
  Regex!char regex;
  TokenEnum type;

  this(Regex!char regex, TokenEnum type)
  {
    this.regex = regex;
    this.type = type;
  }

  auto ignore()
  {
    switch (type)
    {
      case TokenEnum.WHITESPACE:
        return true;
      default:
        return false;
    }
  }
}
