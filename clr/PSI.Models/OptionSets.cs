namespace PSI.Models;

public class OptionSet
{
    private bool _isPlaceHolder;
    public List<Tuple<string, string>> Options { get; set; } = new List<Tuple<string, string>>();

    public bool IsPlaceHolderOptionSet
    {
        get
        {
            return this._isPlaceHolder;
        }
    }

    public string GetSetOptionsCommand()
    {
        throw new NotImplementedException();
        // basically, throw back as many statements as needed (try for 2 or less) e.g., "SET X, Y, Z ON; SET XX, YY, ZZ OFF")
        //  to execute against the database for ... setup of connection details/etc. 
    }

    private OptionSet(bool isPlaceHolder)
    {
        this._isPlaceHolder = isPlaceHolder;
    }

    public static OptionSet NewOptionSet()
    {
        return new OptionSet(false);
    }

    public static OptionSet DeserializedOptionSet(string serializedOptions)
    {
        var output = new OptionSet(false);

        try
        {
            // split options by ; or , 
            // for each pair... 
            //  hand off to AddSetOptions... 


            // NOTE: 
            // WHILE MOST SET xxxx options allow a 'set' of options in the form of { ON | OFF } 
            // there are a FEW 'oddballs' that do allow different types of values. 
            //  e.g., a handful will allow integers - like... 
            //      SET LOCK_TIMEOUT, SET DEADLOCK_PRIORITY, SET QUERY_GOVERNOR_COST_LIMIT
            // 
            // and ... a few will allow TEXT values, like... 
            //      SET DEADLOCK_PRIORITY, SET FIPS_FLAGGER, SET LANGUAGE .... 
            //      SET DATEFORMAT, 
            // and... there's even: 
            //          SET CONTEXT_INFO 0x0BINARY... 

            // so... don't assume { ON | OFF } is the full subset of allowed values. 


        }
        catch
        {
            throw new SyntaxException("Invalid SET Options Specified.");
        }

        return output;
    }

    public static OptionSet PlaceHolderOptionSet()
    {
        return new OptionSet(true);
    }

    public void AddSetOption(string option, string onOff)
    {
        // TODO: validate that "option" is a LEGIT set/connection option.   
        //      and that "onOff" is either ON/OFF (case insensitive)
    }
}