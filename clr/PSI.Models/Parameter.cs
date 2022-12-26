using System;

namespace PSI.Models
{
    public class Parameter
    {
        public string Name { get; private set; }
        public object Value { get; private set; }
        public PsiType Type { get; private set; }
        public PDirection Direction { get; private set; }
        public int Size { get; private set; }
        public int Precision { get; private set; }
        public int Scale { get; private set; }

        //public Parameter(string name, object value)
        //{
        //    // I REALLY hate this approach ... but, it's commonly-enough used. 
        //    //  that said... INFER the PsiType based on the TYPE of $value... 
        //    //      assuming that's what .NET does with things like this... 
        //}

        //public Parameter(string name, PsiType type, object value)
        //{
        //    // depending upon the type... might have to specify some sort of default $size if that makes sense
        //    //      and if a default doesn't make sense ... throw (e.g., I think i COULD default to the LONGEST size for datetime2, right? 
        //    //          and ... bletch... i could do LEN() for size of nvarchar... but... that's just VILE. 
        //    //      as in, i should WARN on crap like this. 
        //    //          or just throw. 
        //    //          which means: congrats! I've got a new feature: -PerfOptions Warn or Throw ... for stuff like this... 
        //}

        //public Parameter(string name, PsiType type, int precision, int scale, object value)
        //    // arguably, this can ONLY be used for decimal/numeric data types (they're the same data type). 
        //    // see this for confirmation: https://learn.microsoft.com/en-us/dotnet/api/system.data.sqlclient.sqlparameter.precision?view=dotnet-plat-ext-7.0#remarks
        //    // and, yeah, interestingly enough... they ONLY need to be specified when ... NULL/OUTPUT?
        //    : this(name, type, value, -1, precision, scale)
        //{

        //}

        // TODO: maybe make VALUE, size, precision, and scope all NULLable instead of the -1 (and meh it might be null) approach I'm using now... 
        //      -1 is too ... magic-number-y.
        public Parameter(string name, PsiType type, PDirection direction, object value, int size = -1, int precision = -1, int scale = -1)
        {
            if (type == PsiType.NotSet)
            {
                throw new InvalidOperationException("Type inference is not yet supported. Please Specify a Type... ");
            }

            if (direction == PDirection.NotSet)
                direction = PDirection.Input;

            this.Name = name;
            this.Type = type;
            this.Direction = direction;
            this.Value = value;
            this.Size = size;
            this.Precision = precision;
            this.Scale = scale;
        }
    }
}