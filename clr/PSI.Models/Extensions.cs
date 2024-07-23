namespace PSI.Models;

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