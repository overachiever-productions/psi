﻿namespace PSI.Models.Tests.unit_tests;

public class SerializedParameterTests
{
    [Test]
    public void Simple_Parameter_String_Is_Split_On_At_Sign()
    {
        var serialized = "@p1 int = 12, @p2 sysname = 'the big brown bear', @p12 varchar(50) = 'this is ascii text vs unicode'";
        var sut = ParameterSet.ParameterSetFromSerializedInput(serialized, "_DEFAULT");

        Assert.That(sut.Parameters.Count, Is.EqualTo(3));
    }

    [Test]
    public void Simple_Parameter_String_Correctly_Maps_Parameter_Name()
    {
        var serialized = "@p1 int = 12, @p2 sysname = 'the big brown bear', @p12 varchar(50) = 'this is ascii text vs unicode'";
        var sut = ParameterSet.ParameterSetFromSerializedInput(serialized, "_DEFAULT");

        Assert.That(sut.Parameters.Count, Is.EqualTo(3));

        StringAssert.AreEqualIgnoringCase("@p1", sut.Parameters[0].Name);
        StringAssert.AreEqualIgnoringCase("@p2", sut.Parameters[1].Name);
        StringAssert.AreEqualIgnoringCase("@p12", sut.Parameters[2].Name);
    }

    [Test]
    public void Simple_Parameter_String_Correctly_Maps_Parameter_Types()
    {
        var serialized = "@p1 int = 12, @p2 sysname = 'the big brown bear', @p12 varchar(50) = 'this is ascii text vs unicode'";
        var sut = ParameterSet.ParameterSetFromSerializedInput(serialized, "_DEFAULT");

        Assert.That(sut.Parameters.Count, Is.EqualTo(3));

        Assert.That(sut.Parameters[0].DataType, Is.EqualTo(DataType.Int));
        Assert.That(sut.Parameters[1].DataType, Is.EqualTo(DataType.Sysname));
        Assert.That(sut.Parameters[2].DataType, Is.EqualTo(DataType.Varchar));
    }

    [Test]
    public void Simple_Parameter_String_Correctly_Maps_Parameter_Sizes()
    {
        var serialized = "@p1 int = 12, @p2 sysname = 'the big brown bear', @p12 varchar(50) = 'this is ascii text vs unicode'";
        var sut = ParameterSet.ParameterSetFromSerializedInput(serialized, "_DEFAULT");

        Assert.That(sut.Parameters.Count, Is.EqualTo(3));
        Assert.That(sut.Parameters[2].Size, Is.EqualTo(50));
    }

    [Test]
    public void Simple_Parameter_String_Correctly_Maps_Parameter_Values()
    {
        var serialized = "@p1 int = 12, @p2 sysname = 'the big brown bear', @p12 varchar(50) = 'this is ascii text vs unicode'";
        var sut = ParameterSet.ParameterSetFromSerializedInput(serialized, "_DEFAULT");

        Assert.That(sut.Parameters.Count, Is.EqualTo(3));

        Assert.That(sut.Parameters[0].Value, Is.EqualTo(12));
        StringAssert.AreEqualIgnoringCase("'the big brown bear'", sut.Parameters[1].Value.ToString());
        StringAssert.AreEqualIgnoringCase("'this is ascii text vs unicode'", sut.Parameters[2].Value.ToString());
    }

    [Test]
    public void Parameter_String_Allows_Escaped_Ticks_In_String_Value()
    {
        var serialized = "@p2 sysname = 'that''s what I said!', @p12 varchar(50) = 'this is ascii text vs unicode'";
        var sut = ParameterSet.ParameterSetFromSerializedInput(serialized, "_DEFAULT");

        Assert.That(sut.Parameters.Count, Is.EqualTo(2));

        StringAssert.AreEqualIgnoringCase("'that''s what I said!'", sut.Parameters[0].Value.ToString());
    }

    [Test]
    public void Parameter_String_Allows_Nested_Ticks_In_String_Value()
    {
        var serialized = "@p1 int = 12, @p2 sysname = 'this is ''tricky'' and stuff', @p12 varchar(50) = 'this is ascii text vs unicode'";
        var sut = ParameterSet.ParameterSetFromSerializedInput(serialized, "_DEFAULT");

        Assert.That(sut.Parameters.Count, Is.EqualTo(3));

        StringAssert.AreEqualIgnoringCase("'this is ''tricky'' and stuff'", sut.Parameters[1].Value.ToString());
    }

    [Test]
    public void Parameter_String_Ignores_At_Sign_Within_Strings()
    {
        var serialized = "@UserId int = 10088, @EmailAddress sysname = 'mike@angrypets.com'";
        var sut = ParameterSet.ParameterSetFromSerializedInput(serialized, "_DEFAULT");

        Assert.That(sut.Parameters.Count, Is.EqualTo(2));

        StringAssert.AreEqualIgnoringCase("'mike@angrypets.com'", sut.Parameters[1].Value.ToString());
    }

    [Test]
    public void Parameter_String_Ignores_Apostrophe_In_Email_Address()
    {
        var serialized = "@UserId int = 10088, @EmailAddress sysname = 'mike.o''mally@angrypets.com'";
        var sut = ParameterSet.ParameterSetFromSerializedInput(serialized, "_DEFAULT");

        Assert.That(sut.Parameters.Count, Is.EqualTo(2));

        StringAssert.AreEqualIgnoringCase("'mike.o''mally@angrypets.com'", sut.Parameters[1].Value.ToString());
    }

    [Test]
    public void Parameter_String_Ignores_Padded_White_Space()
    {
        var serialized = " @UserId   int   =   10088,   @EmailAddress   sysname   =   'mike@angrypets.com'  ";
        var sut = ParameterSet.ParameterSetFromSerializedInput(serialized, "_DEFAULT");

        Assert.That(sut.Parameters.Count, Is.EqualTo(2));

        Assert.That(sut.Parameters[0].Name, Is.EqualTo("@UserId"));
        Assert.That(sut.Parameters[0].DataType, Is.EqualTo(DataType.Int));
        Assert.That(sut.Parameters[0].Value, Is.EqualTo(10088));

        Assert.That(sut.Parameters[1].Name, Is.EqualTo("@EmailAddress"));
        Assert.That(sut.Parameters[1].DataType, Is.EqualTo(DataType.Sysname));
        Assert.That(sut.Parameters[1].Value, Is.EqualTo("'mike@angrypets.com'"));
    }

    // OUTPUTs i.e., make sure I can detect OUTPUT and INPUT/OUTPUT. 
    // RETURN. Make sure I can detect/map RETURN params.

    // NULLs and/or no assigned values. 
}