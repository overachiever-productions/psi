// NOTE: Some of the directives below are NOT needed from within VS, but ARE 100% needed by PowerShell:
global using System;
global using System.IO;
global using System.Text;
global using System.Linq;
global using System.Collections.Generic;
global using System.Text.RegularExpressions;
global using System.Management.Automation;

namespace PSI.Models;

public static class Global
{
    public static RegexOptions SingleLineRegexOptions = RegexOptions.CultureInvariant | RegexOptions.IgnoreCase | RegexOptions.Singleline;
    public static RegexOptions MultiLineRegexOptions  = RegexOptions.CultureInvariant | RegexOptions.IgnoreCase | RegexOptions.Multiline;
}

public static class ExtensionMethods
{
    public static string ReplaceAtIndex(this string source, int index, char replacement)
    {
        if (source == null) throw new ArgumentNullException("source");

        StringBuilder builder = new StringBuilder(source);
        builder[index] = replacement;
        return builder.ToString();
    }
}

public class SyntaxException : Exception
{
    public SyntaxException(string message) : base(message) { }
    public SyntaxException(string message, Exception ex) : base(message, ex) { }
}