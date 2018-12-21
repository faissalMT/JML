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
  if (argv.length>2)
  {
    auto data = readJson(argv[2]);
    auto lex = new Lexer(readText(argv[1]));
    new Parser(lex).getMain().run(&data);
  }
  else
  {
    writeln("Usage: jml script file");
  }

  return 0;
}
