Class dc.musketeersbr.sqlembeddings.providers.OpenAI Extends %RegisteredObject
{

/// Loads an ebedding model from the given model name.
/// 
/// @param modelName The name of the model to be loaded.
/// @return The loaded model as a %SYS.Python object.
ClassMethod LoadEmbeddingModel(modelName As %String = "text-embedding-3-small") As %SYS.Python [ Language = python ]
{
    from langchain_openai import OpenAIEmbeddings

    model = OpenAIEmbeddings(model=modelName)
    return model
}

/// Executes the embeddings using the given model and data.
///  
/// This method is a wrapper around the Hugging Face Transformers library and
/// is used to execute the embeddings using the given model and data.
/// 
/// Args:
///     data (str): The data to be embedded.
///     model: The model to be used for embeddings.
/// 
/// Returns:
///     str: The embeddings as a string.
ClassMethod ExecuteEmbeddings(data As %String, model As %SYS.Python) As %String [ Language = python, Private ]
{
    documents = [data]
    embeddings_list = model.embed_documents(documents)[0]
    #; embeddings_list = [embedding.tolist() for embedding in embeddings_list]
    return str(embeddings_list)
}

}
