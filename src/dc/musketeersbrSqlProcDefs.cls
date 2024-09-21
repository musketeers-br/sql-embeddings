Class dc.musketeersbrSqlProcDefs Extends %RegisteredObject
{

/// Embed a given value using a model.
/// 
/// This method embeds the given value using the specified model.
/// The method returns a vector of doubles representing the embeddings.
/// 
/// @param valueToEmbed The value to be embedded.
/// @param modelName The name of the model to be used.
/// @return A vector of doubles representing the embeddings.
ClassMethod Embedding(valueToEmbed = "", modelName As %String = "all-MiniLM-L6-v2") As %Vector [ SqlName = embedding, SqlProc ]
{
    Set obj = ##class(dc.musketeersbr.sqlembeddings.Main).%New(valueToEmbed, modelName)
    Return obj.Execute()
}

}
