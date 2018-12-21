import tokenspec;

class Token
{
  string capture;
  TokenSpec spec;

  this(TokenSpec spec, string capture)
  {
    this.capture = capture;
    this.spec = spec;
  }

  auto type()
  {
    return spec.type;
  }

  auto value()
  {
    return capture;
  }

  override string toString()
  {
    return capture;
  }
}
