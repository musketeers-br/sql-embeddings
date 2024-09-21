/// Definition for the Stored Function dc.embedding()
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
ClassMethod Embedding(valueToEmbed = "", modelName As %String = "fastembed/BAAI/bge-small-en-v1.5") As %Vector [ SqlName = embedding, SqlProc ]
{
    Set obj = ##class(dc.musketeersbr.sqlembeddings.Main).%New(valueToEmbed, modelName)
    Return obj.Execute()
}

}
