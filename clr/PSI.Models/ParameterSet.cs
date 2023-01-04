using System.Collections.Generic; // Declaration NOT needed by newer versions of C#/Visual Studio... but (some versions of) PowerShell will choke if NOT in place.

namespace PSI.Models
{
    public class ParameterSet
    {
        public string SetName { get; set; }
        public List<Parameter> Parameters { get; private set; }

        internal ParameterSet()
        {
            this.Parameters = new List<Parameter>();
        }

        public void Add(Parameter added)
        {
            // TODO: check for ... parameter already existing - by name... 
            //      i.e., might want to make the List<Parameter> a Dictionary<string, Parameter> instead?
            // ACTUALLY: might want to have both a Dictionary<String, Parameter> AND a List<Parameter>
            //      that's wee bit over 'overhead' (but, seriously: who cares it's a TINY amount of memory). 
            //      the BENEFITs would be: 
            //          - I can quickly check for existing param names 
            //          - When i get/iterate over List<Parameter> the params are in the ORDER they were added. 
            // in short, think of having both Dictionary<> and List<> as a weak-sauce doubly-linked-list or whatever. 

            this.Parameters.Add(added);
        }
    }
}