/// # todo: implement provider parameter
/// # todo: implement factory design pattern
Class dc.musketeersbr.sqlembeddings.Embeddings Extends %RegisteredObject
{

ClassMethod GetEmbeddingsProvider(providerName As %String) As %String
{
    If providerName = "sentence_transformers" {
        Return "dc.musketeersbr.sqlembeddings.providers.SentenceTransformers"
    } ElseIf providerName = "fastembed" {
        Return "dc.musketeersbr.sqlembeddings.providers.FastEmbed"
    } Else {
        Throw ##class(%Exception.General).%New("Invalid provider name")
    }
}

}
