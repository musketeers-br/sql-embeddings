Class dc.musketeersbr.sqlembeddings.providers.SpaCy Extends ProviderAbstract
{

/// Loads an ebedding model from the given model name.
/// 
/// @param modelName The name of the model to be loaded.
/// @return The loaded model as a %SYS.Python object.
ClassMethod ExecuteLoadModel(modelName As %String = "en_core_web_sm") As %SYS.Python [ Language = python ]
{
    from langchain_community.embeddings.spacy_embeddings import SpacyEmbeddings

    model = SpacyEmbeddings(model=modelName)
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
ClassMethod ExecuteEmbeddings(data As %String, model As %SYS.Python) As %String [ Language = python ]
{
    documents = [data]
    embeddings_list = model.embed_documents(documents)[0]
    return str(embeddings_list)
}

}
