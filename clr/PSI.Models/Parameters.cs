namespace PSI.Models
{
    public class Parameter
    {
        public string Name { get; internal set; }
        public object Value { get; internal set; }
        public DataType DataType { get; internal set; }
        public ParameterDirection Direction { get; internal set; }
        public int Size { get; internal set; }
        public int Precision { get; internal set; }
        public int Scale { get; internal set; }

        internal Parameter() { }

        // TODO: maybe make VALUE, size, precision, and scope all NULLable instead of the -1 (and meh it might be null) approach I'm using now... 
        //      -1 is too ... magic-number-y.
        //      and/or just create different 'overloads' of the .ctor
        public Parameter(string name, DataType dataType, ParameterDirection direction, object value, int size = -1, int precision = -1, int scale = -1)
        {
            if (dataType == DataType.NotSet)
                throw new InvalidOperationException("DataType inference is not yet supported. Please Specify a DataType... ");

            if (direction == ParameterDirection.NotSet)
                direction = ParameterDirection.Input;

            this.Name = name;
            this.DataType = dataType;
            this.Direction = direction;
            this.Value = value;
            this.Size = size;
            this.Precision = precision;
            this.Scale = scale;
        }
    }

    public class ParameterSet
    {
        private const string BOGUS_SET_NAME = "Psi_Bogus_C9F014B5-9C08-4C9D-B205-E3A7DFAB3C18";
        public string ParameterSetName { get; private set; }
        public List<Parameter> Parameters { get; private set; }

        internal ParameterSet(string parameterSetName)
        {
            this.Parameters = new List<Parameter>();
            this.ParameterSetName = parameterSetName;
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

        public static ParameterSet ParameterSetFromSerializedInput(string serializedParameters, string setName)
        {
            ParameterSet output = new ParameterSet(setName);

            // TODO ... validate that the string isn't null/empty... and that it meets 'basic' requirements
            //  or, maybe just wrap everything in try catch? 

            // TODO: splitting on "," won't work if there's a decimal/numeric in the mix... cuz ... that'll be @something decimal(8,2) or whatever..
            //      so, I'm going to have to find a solid REGEX that accounts for this. 
            //      OR... I'm going to have to cheat and see if numeric/decimal exists in the string in question and .. if so ... replace the , inside the (,) ... with something else... 
            //      i.e., either I get a single regex that IGNOREs commas inside of () or ... i find all , inside of () + make sure they're part of decimal/numeric and ... 'replace' them to 
            //          then make things tons easier to parse/tackle 'down the road'.
            if (serializedParameters.Contains("decimal") || serializedParameters.Contains("numeric"))
                throw new NotImplementedException(
                    "Decimal and Numeric parameters are not yet supported - they gunk-up parsing logic (for now).");

            string[] parameters = serializedParameters.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

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
                Regex r = new Regex(@"(?<name>.+\s)(?<dataType>.+)");
                Match m = r.Match(declaration);

                if (m.Success)
                {
                    p.Name = m.Groups["name"].Value.Trim();

                    string type = m.Groups["dataType"].Value.Trim();
                    string sizing = null;
                    if (type.Contains("("))
                    {
                        sizing = type.Substring(type.IndexOf("("), type.Length);
                        type = type.Replace(sizing, "");
                    }

                    DataType dataType = PsiMapper.GetPsiType(type);
                    p.DataType = dataType;

                    if (sizing != null)
                    {
                        // TODO: verify that the dataType is sizeable/etc... 

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
                    switch (p.DataType)
                    {
                        case DataType.NotSet:
                            throw new InvalidOperationException("Psi Framework Error.");
                        case DataType.Char:
                        case DataType.Varchar:
                        case DataType.VarcharMax:
                        case DataType.NChar:
                        case DataType.NVarchar:
                        case DataType.NVarcharMax:
                        case DataType.Sysname:
                        case DataType.Xml:  // i THINK this'll work just fine... 
                            p.Value = value;
                            break;
                        case DataType.Binary:
                        case DataType.Varbinary:
                        case DataType.VarbinaryMax:
                            throw new NotFiniteNumberException("not done yet");
                        // what I want here is ... p.Value = value.ToByteArray() or whatever would make sense here: https://learn.microsoft.com/en-us/dotnet/framework/data/adonet/configuring-parameters-and-parameter-data-types
                        // looks like this is it: https://stackoverflow.com/a/38140138/11191
                        //break;
                        case DataType.Bit:
                            // TODO: test this... 
                            p.Value = Boolean.Parse(value);
                            break;
                        case DataType.TinyInt:
                            p.Value = Convert.ToByte(value);
                            break;
                        case DataType.SmallInt:
                            p.Value = Convert.ToInt16(value);
                            break;
                        case DataType.Int:
                            p.Value = Convert.ToInt32(value);
                            break;
                        case DataType.BigInt:
                            p.Value = Convert.ToInt64(value);
                            break;
                        case DataType.Numeric:
                        case DataType.Decimal:
                            p.Value = Convert.ToDecimal(value);
                            break;
                        case DataType.SmallMoney:
                        case DataType.Money:
                            p.Value = Convert.ToSingle(value); // TODO: need to test/review this ... 
                            break;
                        case DataType.Float:
                            p.Value = Convert.ToDouble(value);
                            break;
                        case DataType.Real:
                            p.Value = Convert.ToSingle(value);
                            break;
                        case DataType.Date:
                            //p.Value = DateOnly.Parse(value);
                            p.Value = DateTime.Parse(value); // TODO: need to evaluate this... 
                            break;
                        case DataType.Time:
                            //p.Value = TimeOnly.Parse(value);
                            p.Value = TimeSpan.Parse(value);
                            break;
                        case DataType.SmallDateTime:
                        case DataType.DateTime:
                        case DataType.DateTime2:
                            p.Value = DateTime.Parse(value);
                            break;
                        case DataType.UniqueIdentifier:
                            p.Value = Guid.Parse(value);
                            break;
                        case DataType.DateTimeOffset:
                        case DataType.Image:
                        case DataType.Text:
                        case DataType.NText:
                        case DataType.SqlVariant:
                        case DataType.Geometry:
                        case DataType.Geography:
                        case DataType.TimeStamp:
                            throw new InvalidOperationException($"DataType [{p.DataType}] is NOT supported for inline/serialized Psi Parameters.");
                        default:
                            throw new NotImplementedException("Psi Framework Error. Invalid DataType detected.");
                    }
                }

                p.Direction = ParameterDirection.Input;
                if (isOutput)
                {
                    p.Direction = p.Value != null ? ParameterDirection.InputOutput : ParameterDirection.Output;
                }

                output.Parameters.Add(p);
            }

            return output;
        }

        public static ParameterSet EmptyParameterSet()
        {
            return new ParameterSet(BOGUS_SET_NAME);
        }

        public bool IsPlaceHolderParameterSetOnly
        {
            get
            {
                return this.ParameterSetName == BOGUS_SET_NAME;
            }
        }
    }

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

            ParameterSet newSet = new ParameterSet(name);

            this.ParameterSets.Add(name, newSet);
        }

        public void AddParameterToSet(string set, Parameter added)
        {
            ParameterSet target = this.ParameterSets[set];
            if (target == null)
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
    }

    // Fodder: https://learn.microsoft.com/en-us/dotnet/framework/data/adonet/data-dataType-mappings-in-ado-net
    // REFACTOR: ParameterMapper? 
    public class PsiMapper
    {
        // Refactor: Map[Psi]Type() instead of GetPsiType?
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