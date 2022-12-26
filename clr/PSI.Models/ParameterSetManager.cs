using System;
using System.Collections.Generic; // Declaration NOT needed by newer versions of C#/Visual Studio... but (some versions of) PowerShell will choke if NOT in place.
using System.Xml.Linq;

namespace PSI.Models
{
    public class ParameterSetManager
    {
        public Dictionary<string, ParameterSet> ParameterSets { get; private set; }

        public static ParameterSetManager Instance => new ParameterSetManager();

        private ParameterSetManager()
        {
            this.ParameterSets = new Dictionary<string, ParameterSet>();
        }

        public void AddParameterSet(string name)
        {
            if (this.ParameterSets.ContainsKey(name))
                throw new InvalidOperationException($"A ParameterSet with the name of [{name}] already exists.");

            ParameterSet newSet = new ParameterSet();

            this.ParameterSets.Add(name, newSet);
        }

        public void AddParameterToSet(string set, Parameter added)
        {
            ParameterSet target = this.ParameterSets[set];
            if(target == null)
                throw new InvalidOperationException("Set not found");

            target.Add(added);
        }

        public ParameterSet GetParameterSetByName(string name)
        {
            return this.ParameterSets[name];
        }
    }
}