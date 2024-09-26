Class dc.musketeersbr.sqlembeddings.Cache Extends %Persistent
{

Property ModelName As %String(MAXLEN = "");

Property Key As %String(MAXLEN = "");

Property Embeddings As %String(MAXLEN = "");

Index idxModelNameKey On (ModelName, Key) [ Unique ];

ClassMethod SaveEmbeddings(modelName As %String, key As %String, embeddings As %String) As %Status
{
    Do ##class(Logger).Debug("Saving embeddings for model "_modelName_" and key "_key)
    Set instance = ..%New()
    Set instance.ModelName = modelName
    Set hashKey = $SYSTEM.Encryption.MD5Hash(key)
    Set instance.Key = hashKey
    Set instance.Embeddings = embeddings
    Set st = instance.%Save()
    Do ##class(Logger).Debug("Saved embeddings for model "_modelName_" and key "_key)
    Return st
}

ClassMethod GetEmbeddings(modelName As %String, key As %String) As %String
{
    Do ##class(Logger).Debug("Getting embeddings for model "_modelName_" and key "_key)
    Set hashKey = $SYSTEM.Encryption.MD5Hash(key)
    Set instance = ..idxModelNameKeyOpen(modelName, hashKey)
    If $IsObject(instance) {
        Set embeddings = instance.Embeddings
    } Else {
        Set embeddings = ""
    }
    Do ##class(Logger).Debug("Got embeddings for model "_modelName_" and key "_key)
    Return embeddings
}

Storage Default
{
<Data name="CacheDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ModelName</Value>
</Value>
<Value name="3">
<Value>Key</Value>
</Value>
<Value name="4">
<Value>Embeddings</Value>
</Value>
</Data>
<DataLocation>^dc.musketeersbr.sqle82C1.CacheD</DataLocation>
<DefaultData>CacheDefaultData</DefaultData>
<IdLocation>^dc.musketeersbr.sqle82C1.CacheD</IdLocation>
<IndexLocation>^dc.musketeersbr.sqle82C1.CacheI</IndexLocation>
<StreamLocation>^dc.musketeersbr.sqle82C1.CacheS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
