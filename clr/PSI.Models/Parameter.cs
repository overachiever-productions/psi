using System;

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

        internal Parameter()
        {
        }

        // TODO: maybe make VALUE, size, precision, and scope all NULLable instead of the -1 (and meh it might be null) approach I'm using now... 
        //      -1 is too ... magic-number-y.
        //      and/or just create different 'overloads' of the .ctor
        public Parameter(string name, DataType dataType, ParameterDirection direction, object value, int size = -1, int precision = -1, int scale = -1)
        {
            if (dataType == DataType.NotSet)
            {
                throw new InvalidOperationException("DataType inference is not yet supported. Please Specify a DataType... ");
            }

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
}