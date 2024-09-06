namespace PSI.Models;

// i.e., sqlclient, odbc, oledb... 
// nice: 
// https://learn.microsoft.com/en-us/dotnet/api/system.data.odbc.odbcconnectionstringbuilder?view=net-8.0
// https://learn.microsoft.com/en-us/dotnet/api/system.data.oledb.oledbconnectionstringbuilder?view=net-8.0 
// and, one thing that's SUPER clear: OLEDB and ODBC don't have NEAR the number of connection options that SqlClient does. 
// specifically, they don't have EXPLICIT properties for: 
//      ApplicationIntent (Ah, though they do have IsReadOnly)
//      Connection retry logic (# of retries and times)
//      TIMEOUT. wtf? 
//      AlwaysEncrypted 'stuff' ... 
//      Encrypt (i.e., .... TLS? + TrustServerCert)
//      Connection Pooling directives (loadbalancetimeout, maxpoolsize, minpoolsize)
//      MultiSubnetFailover. 
//      PacketSize
//                   
// BUT, the different drivers (OLEDB and ODBC) DO provide connection-string details for 'all the options'
// e.g., see this: 
// https://learn.microsoft.com/en-us/sql/relational-databases/native-client/applications/using-connection-string-keywords-with-sql-server-native-client?view=sql-server-ver15&viewFallbackFrom=sql-server-ver16 
// and here's the anchor (same page as above) for OLEDB:
// https://learn.microsoft.com/en-us/sql/relational-databases/native-client/applications/using-connection-string-keywords-with-sql-server-native-client?view=sql-server-ver15#ole-db-provider-connection-string-keywords
// which means, I'm going to need something to abstract all of this 'stuff'

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
    public int QueryTimeout { get; set; } = -1;

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
            return;  // this is a weird hack to avoid having to avoid branching logic within PowerShell funcs. 

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
        output.QueryTimeout = this.QueryTimeout;

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