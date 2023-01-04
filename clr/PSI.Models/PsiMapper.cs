using System;

namespace PSI.Models
{
    // Fodder: https://learn.microsoft.com/en-us/dotnet/framework/data/adonet/data-type-mappings-in-ado-net
    public class PsiMapper
    {
        // Refactor: MapType() instead of GetPType?
        public static PsiType GetPsiType(string input)
        {
            // final param in Enum.Parse is to IGNORE case sensitivity. 
            return (PsiType)Enum.Parse(typeof(PsiType), input, true);
        }

        public static PDirection GetPDirection(string input)
        {
            return (PDirection)Enum.Parse(typeof(PDirection), input, true);
        }
    }
}