import std.file;
import std.stdio;
import std.json;
import std.regex;

import parser;
import token;
import tokenspec;
import lexer;

auto readJson(string filename)
{
  return parseJSON(readText(filename));
}

int main(string[] argv)
{
  JSONValue data;
  if (argv.length > 1)
  {
    if (argv.length == 2)
    {
      data = readJson("/dev/stdin");
    }
    else if (argv.length == 3)
    {
      data = readJson(argv[2]);
    }
    auto lex = new Lexer(readText(argv[1]));
    new Parser(lex).getMain().run(&data);
    return 0;
  }

  writeln("Usage: jml script file");
  return 0;
}
