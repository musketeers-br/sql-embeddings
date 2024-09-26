Class dc.musketeersbr.sqlembeddings.unittests.Cache Extends %UnitTest.TestCase
{

/// Unit test for the method SaveEmebddings of the class dc.musketeersbr.sqlembeddings.Cache
Method TestSaveEmebddings() As %Status
{
    Set exception = ""
    TSTART

    Try {
        // save the embedding
        Set instance = ##class(dc.musketeersbr.sqlembeddings.Cache).%New()
        Set instance.ModelName = "test"
        Set instance.Key = "key"
        Set instance.Embeddings = "embeddings"
        Set sc = instance.%Save()
        Do $$$AssertStatusOK(sc, "Saving the embedding should succeed")

        // check if the embedding was saved in the database using SQL
        Set sql = "SELECT Embeddings FROM dc_musketeersbr_sqlembeddings.Cache WHERE ModelName = ? AND Key = ?"
        Set statement = ##class(%SQL.Statement).%New()
        Set status = statement.%Prepare(sql)
        Set result = statement.%Execute(instance.ModelName, instance.Key)
        Do $$$AssertStatusOK(status, "Preparing and executing the SQL statement should succeed")
    } Catch ex {
        zw ex
        Set exception = ex
    }

    TROLLBACK

    If $IsObject(exception) {
        Throw exception
    }

    Return $$$OK
}

/// Unit test for the method GetEmbeddings of the class dc.musketeersbr.sqlembeddings.Cache
Method TestGetEmbeddings() As %Status
{
    Set exception = ""
    TSTART

    Try {
        // save the embedding
        Set expectedEmbeddings = "embeddings"
        Set ModelName = "test"
        Set Key = "key"
        Set sc = ##class(dc.musketeersbr.sqlembeddings.Cache).SaveEmbeddings("test", "key", expectedEmbeddings)
        Do $$$AssertStatusOK(sc, "Saving the embedding should succeed")

        // check if the embedding was saved using the method GetEmbeddings
        Set result = ##class(dc.musketeersbr.sqlembeddings.Cache).GetEmbeddings(ModelName, Key)
        write !,result,!
        Do $$$AssertEquals(result, "embeddings", "GetEmbeddings should return the saved embedding; expected '"_expectedEmbeddings_"', got "_result)
    } Catch ex {
        zw ex
        Set exception = ex
    }

    TROLLBACK

    If $IsObject(exception) {
        Throw exception
    }

    Return $$$OK
}

}
