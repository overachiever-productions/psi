using System;
using System.Collections.Generic; // Declaration NOT needed by newer versions of C#/Visual Studio... but (some versions of) PowerShell will choke if NOT in place.
using System.Text.RegularExpressions; 
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

            ParameterSet newSet = new ParameterSet { SetName = name };

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

        public void RemoveParameterSet(string name)
        {
            this.ParameterSets.Remove(name);
        }

        public ParameterSet ParameterSetFromSerializedInput(string serializedParameters, string setName)
        {
            // TODO ... validate that the string isn't null/empty... and that it meets 'basic' requirements
            //  or, maybe just wrap everything in try catch? 

            // TODO: splitting on , won't work if there's a decimal/numeric in the mix... cuz ... that'll be @something decimal(8,2) or whatever..
            //      so, I'm going to have to find a solid REGEX that accounts for this. 
            //      OR... I'm going to have to cheat and see if numeric/decimal exists in the string in question and .. if so ... replace the , inside the (,) ... with something else... 
           //      i.e., either I get a single regex that IGNOREs commas inside of () or ... i find all , inside of () + make sure they're part of decimal/numeric and ... 'replace' them to 
            //          then make things tons easier to parse/tackle 'down the road'.
            if (serializedParameters.Contains("decimal") || serializedParameters.Contains("numeric"))
                throw new NotImplementedException(
                    "Decimal and Numeric parameters are not yet supported - they gunk-up parsing logic (for now).");

            string[] parameters = serializedParameters.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

            // REFACTOR? this is all a bit clunky - but needed to 'overwrite' the default parameter set:
            this.RemoveParameterSet(setName);
            this.AddParameterSet(setName);
            ParameterSet output = GetParameterSetByName(setName);

            foreach (string parameter in parameters)
            {
                bool isOutput = parameter.Trim().Contains(" OUTPUT");

                // NOTE: removing OUTPUT AND splitting here: 
                string[] parts = parameter.Replace(" OUTPUT", "").Split('=', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
                if (parts.Length > 2)
                    throw new InvalidOperationException("too many parts");

                Parameter p = new Parameter();

                string declaration = parts[0];
                // TODO: this regex needs some help... 
                Regex r = new Regex(@"(?<name>.+\s)(?<type>.+)");
                Match m = r.Match(declaration);

                if (m.Success)
                {
                    p.Name = m.Groups["name"].Value.Trim();

                    string type = m.Groups["type"].Value.Trim();
                    string sizing = null;
                    if (type.Contains("("))
                    {
                        sizing = type.Substring(type.IndexOf("("), type.Length);
                        type = type.Replace(sizing, "");
                    }

                    PsiType psiType = PsiMapper.GetPsiType(type);
                    p.Type = psiType;

                    if (sizing != null)
                    {
                        // TODO: verify that the psiType is sizeable/etc... 

                        sizing = sizing.Replace("(", "").Replace(")", "");
                        if (type == "decimal" || type == "numeric")
                        {
                            p.Precision = int.Parse(sizing.Split(",")[0]);
                            p.Scale = int.Parse(sizing.Split(",")[1]);
                        }

                        p.Size = int.Parse(sizing);
                    }
                }

                string value = null;
                if (parts.Length == 2)
                    value = parts[1];
                if (value != null)
                {
                    // this is FUGLY: 
                    switch (p.Type)
                    {
                        case PsiType.NotSet:
                            throw new InvalidOperationException("Psi Framework Error.");
                        case PsiType.Char: 
                        case PsiType.Varchar:
                        case PsiType.VarcharMax:
                        case PsiType.NChar:
                        case PsiType.NVarchar:
                        case PsiType.NVarcharMax:
                        case PsiType.Sysname:
                        case PsiType.Xml:  // i THINK this'll work just fine... 
                            p.Value = value;
                            break;
                        case PsiType.Binary:
                        case PsiType.Varbinary:
                        case PsiType.VarbinaryMax:
                            throw new NotFiniteNumberException("not done yet");
                            // what I want here is ... p.Value = value.ToByteArray() or whatever would make sense here: https://learn.microsoft.com/en-us/dotnet/framework/data/adonet/configuring-parameters-and-parameter-data-types
                            // looks like this is it: https://stackoverflow.com/a/38140138/11191
                            //break;
                        case PsiType.Bit:
                            // TODO: test this... 
                            p.Value = Boolean.Parse(value);
                            break;
                        case PsiType.TinyInt:
                            p.Value = Convert.ToByte(value);
                            break;
                        case PsiType.SmallInt:
                            p.Value = Convert.ToInt16(value);
                            break;
                        case PsiType.Int:
                            p.Value = Convert.ToInt32(value);
                            break;
                        case PsiType.BigInt:
                            p.Value = Convert.ToInt64(value);
                            break;
                        case PsiType.Numeric:
                        case PsiType.Decimal:
                            p.Value = Convert.ToDecimal(value);
                            break;
                        case PsiType.SmallMoney:
                        case PsiType.Money:
                            p.Value = Convert.ToSingle(value); // TODO: need to test/review this ... 
                            break;
                        case PsiType.Float:
                            p.Value = Convert.ToDouble(value);
                            break;
                        case PsiType.Real:
                            p.Value = Convert.ToSingle(value);
                            break;
                        case PsiType.Date:
                            //p.Value = DateOnly.Parse(value);
                            p.Value = DateTime.Parse(value); // TODO: need to evaluate this... 
                            break;
                        case PsiType.Time:
                            //p.Value = TimeOnly.Parse(value);
                            p.Value = TimeSpan.Parse(value);
                            break;
                        case PsiType.SmallDateTime:
                        case PsiType.DateTime:
                        case PsiType.DateTime2:
                            p.Value = DateTime.Parse(value);
                            break;
                        case PsiType.UniqueIdentifier:
                            p.Value = Guid.Parse(value);
                            break;
                        case PsiType.DateTimeOffset:
                        case PsiType.Image:
                        case PsiType.Text:
                        case PsiType.NText:
                        case PsiType.SqlVariant:
                        case PsiType.Geometry:
                        case PsiType.Geography:
                        case PsiType.TimeStamp:
                            throw new InvalidOperationException($"Type [{p.Type}] is NOT supported for inline/serialized Psi Parameters.");
                        default:
                            throw new NotImplementedException("Psi Framework Error. Invalid PsiType detected.");
                    }
                }

                p.Direction = PDirection.Input;
                if (isOutput)
                {
                    p.Direction = p.Value != null ? PDirection.InputOutput : PDirection.Output;
                }

                output.Parameters.Add(p);
            }

            return output;
        }
    }
}