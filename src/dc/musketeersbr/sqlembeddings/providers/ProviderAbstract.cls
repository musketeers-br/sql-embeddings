Class dc.musketeersbr.sqlembeddings.providers.ProviderAbstract Extends %RegisteredObject
{

ClassMethod ExecuteLoadModel(modelName As %String) As %SYS.Python [ Abstract, Language = python, Private ]
{
}

/// Loads an ebedding model from the given model name.
/// 
/// @param modelName The name of the model to be loaded.
/// @return The loaded model as a %SYS.Python object.
ClassMethod LoadEmbeddingModel(modelName As %String, providerClassName As %String) As %SYS.Python [ Final, Language = python ]
{
    import iris

    iris.cls('dc.musketeersbr.sqlembeddings.Logger').Debug(f'Loading model: {modelName}')
    #; model = iris.cls('dc.musketeersbr.sqlembeddings.providers.ProviderAbstract').ExecuteLoadModel(modelName)
    iris.cls('dc.musketeersbr.sqlembeddings.Logger').Debug(f'providerClassName: {providerClassName}')
    model = iris.cls(providerClassName).ExecuteLoadModel(modelName)
    iris.cls('dc.musketeersbr.sqlembeddings.Logger').Debug(f'Loaded model: {modelName}')
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
ClassMethod ExecuteEmbeddings(data As %String, model As %SYS.Python) As %String [ Abstract, Language = python, Private ]
{
}

ClassMethod ExecuteEmbeddingsWithCache(data As %String, modelName As %SYS.Python) As %String [ Private ]
{
    Do ##class(dc.musketeersbr.sqlembeddings.Logger).Debug("ExecuteEmbeddingsWithCache data "_data_" and model "_modelName)
    Set cache = ##class(dc.musketeersbr.sqlembeddings.Cache).%New()
    Return cache.GetEmbeddings(modelName, data)
}

ClassMethod GetEmbeddings(data As %String, model As %SYS.Python, modelName As %String) As %String [ Final ]
{
    Do ##class(dc.musketeersbr.sqlembeddings.Logger).Debug("Getting embeddings for data "_data_" and model "_modelName)
    Set embeddings = ..ExecuteEmbeddingsWithCache(data, modelName)
    If embeddings = "" {
        Do ##class(dc.musketeersbr.sqlembeddings.Logger).Debug("Embeddings not found in cache for data "_data_" and model "_modelName)
        Do ##class(dc.musketeersbr.sqlembeddings.Logger).Debug("Getting embeddings for data "_data_" and model "_modelName)

        Set embeddings = ..ExecuteEmbeddings(data, model)

        Do ##class(dc.musketeersbr.sqlembeddings.Logger).Debug("Got embeddings for data "_data_" and model "_modelName)

        Do ##class(dc.musketeersbr.sqlembeddings.Logger).Debug("Saving embeddings for data "_data_" and model "_modelName)
        Do ##class(dc.musketeersbr.sqlembeddings.Cache).SaveEmbeddings(modelName, data, embeddings)
        Do ##class(dc.musketeersbr.sqlembeddings.Logger).Debug("Saved embeddings for data "_data_" and model "_modelName)
    } Else {
        Do ##class(dc.musketeersbr.sqlembeddings.Logger).Debug("Got embeddings from cache for data "_data_" and model "_modelName)
    }
    Return embeddings
}

}
