namespace PSI.Models;

public interface ICloneable<T>
{
    T Clone();
}

public class Connection : ICloneable<Connection>
{
    public string Server { get; protected set; }
    public FrameworkType Framework { get; private set; }
    public PSCredential Credential { get; private set; }
    public string Database { get; protected set; } = "master";

    public int ConnectionTimeout { get; set; } = -1;
    public int CommandTimeout { get; set; } = -1;

    public bool Encrypt { get; set; } = false;
    public bool TrustServerCertificate { get; set; } = false;
    public bool ReadOnly { get; set; } = false;

    public string ApplicationName { get; set; } = "PSI.Command";

    protected Connection(FrameworkType frameworkType, string serverName)
    {
        this.Framework = frameworkType;
        this.Server = serverName;
    }

    public static Connection FromConnectionString(FrameworkType frameworkType, string connectionString)
    {
        // NOTE: framework type might be AUTO right now and/or ... could be different than what's in the connection-string. 
        return new Connection(frameworkType, "from connection string");
    }

    public static Connection FromServerName(FrameworkType frameworkType, string serverName)
    {
        return new Connection(frameworkType, serverName);
    }

    public Connection GetBatchConnection(PSCredential credential, string targetDatabase)
    {
        var output = this.Clone();
        output.AddCredential(credential);
        output.SetTargetDatabase(targetDatabase);

        return output;
    }

    private void AddCredential(PSCredential credential)
    {
        if (credential.UserName == "Psi_Bogus_C9F014B5-9C08-4C9D-B205-E3A7DFAB3C18")
            return;  // Hack to avoid having to avoid branching logic within PowerShell funcs. 

        this.Credential = credential;
    }

    private void SetTargetDatabase(string database)
    {
        this.Database = database;
    }

    public Connection Clone()
    {
        var output = new Connection(this.Framework, this.Server);
        
        output.ConnectionTimeout = this.ConnectionTimeout;
        output.CommandTimeout = this.CommandTimeout;

        output.Encrypt = this.Encrypt;
        output.TrustServerCertificate = this.TrustServerCertificate;
        output.ReadOnly = this.ReadOnly;

        output.ApplicationName = this.ApplicationName;

        // TODO: if there's existing ConnectionString info... then output.ConnString = this.ConnString
        // OR... whatever makes sense to 'copy out' ... 
        // etc. 

        return output;
    }
}