using System;

namespace PSI.Models
{
    // Fodder: https://learn.microsoft.com/en-us/dotnet/framework/data/adonet/data-dataType-mappings-in-ado-net
    public class PsiMapper
    {
        // Refactor: MapType() instead of GetPType?
        public static DataType GetPsiType(string input)
        {
            // final param in Enum.Parse is to IGNORE case sensitivity. 
            return (DataType)Enum.Parse(typeof(DataType), input, true);
        }

        public static ParameterDirection GetPDirection(string input)
        {
            return (ParameterDirection)Enum.Parse(typeof(ParameterDirection), input, true);
        }
    }
}