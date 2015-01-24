module ddotenv.dotenv;

private enum LineType { Whitespace, Directive };

private struct Line
{
    LineType lineType;
    string key;
    string value;
}

public class DotEnvFormatException : Exception
{
    pure @safe nothrow this(string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
       super(".env format error", file, line, next);
    }
}

public void loadDotEnv()
{
    loadDotEnv(".env", false);
}

public void loadDotEnv(string path)
{
    loadDotEnv(path, true);
}

private void loadDotEnv(string path, bool throwOnError)
{
    import std.stdio : File; 
    import std.exception : ErrnoException;
    File envFile;
    try {
        envFile = File(path, "r");
    } catch(ErrnoException e) {
      if( throwOnError ) throw e;
      return;
    }     
      
    foreach(line; envFile.byLine)
    {
        auto parsedLine = parseLine(line);
        if( parsedLine.lineType == LineType.Directive )
        {
            import std.process : environment;
            environment[parsedLine.key] = parsedLine.value;
        }
    }
}

private @safe Line parseLine(const char[] line)
{
   import std.regex : ctRegex, matchFirst;

   Line result;
   result.lineType = LineType.Whitespace;

   auto patternForBlankLine = ctRegex!(`^\s*(?:#.*)?$`);
   auto patternForSimpleLine = ctRegex!(`^\s*(?:export\s+)?(\S+)\s*=\s*([^#"]*)(?:#.*)?$`);
   
   if( matchFirst(line, patternForBlankLine) )
   {
       return result;
   }

   auto simpleCaptures = matchFirst(line, patternForSimpleLine);
   
   if( simpleCaptures.empty() )
   {
       throw new DotEnvFormatException();
   } 
   
   import std.string : stripRight;

   result.key = simpleCaptures[1].idup;
   result.value = simpleCaptures[2].idup.stripRight();
   result.lineType = LineType.Directive;
 
   return result;
}

unittest 
{
   assert( parseLine("# comment").lineType == LineType.Whitespace );
   auto parsed = parseLine("KEY=VALUE");
   assert( parsed.key == "KEY" && parsed.value == "VALUE" );

   parsed = parseLine("KEY=val # hello!");
   assert( parsed.value == "val" );
   
   parsed = parseLine("  key=value");
   assert( parsed.key == "key" );
   
}



