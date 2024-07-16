using System;

namespace PSI.Models
{
    public class Parameter
    {
        public string Name { get; internal set; }
        public object Value { get; internal set; }
        public PsiType Type { get; internal set; }
        public PDirection Direction { get; internal set; }
        public int Size { get; internal set; }
        public int Precision { get; internal set; }
        public int Scale { get; internal set; }

        internal Parameter()
        {
        }

        // TODO: maybe make VALUE, size, precision, and scope all NULLable instead of the -1 (and meh it might be null) approach I'm using now... 
        //      -1 is too ... magic-number-y.
        //      and/or just create different 'overloads' of the .ctor
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