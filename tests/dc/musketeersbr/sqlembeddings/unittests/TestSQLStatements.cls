Class dc.musketeersbr.sqlembeddings.unittests.TestSQLStatements Extends %UnitTest.TestCase
{

Method TestHappyPath() As %Status
{
    New SQLCODE
    &SQL(
    select dc.embedding('test', 'langchain/fake-provider') into :embeddings
    )
    Do AssertSQLExecutionIsOK(SQLCODE)
    Do $$$AssertNotEquals(embeddings, "", "embeddings is not empty")

    New SQLCODE
    &SQL(
    create table if not exists testtable(
        document varchar(1024),         -- the text to be embedded
        embeddings vector(double, 384)  -- store fastembed embeddings using its model bge-small-en-v1.5
    ))
    Do AssertSQLExecutionIsOK(SQLCODE)

    New SQLCODE
    &SQL(
    delete from SQLUser.testtable
    )
    Do AssertSQLExecutionIsOK(SQLCODE)

    NEW SQLCODE
    &SQL(
    insert into SQLUser.testtable (
        document, 
        embeddings
    ) values (
        'my text', 
        dc.embedding('my text', 'langchain/fake-provider')
    ))
    Do AssertSQLExecutionIsOK(SQLCODE)

    NEW SQLCODE
    &SQL(
    select * into :document, :embeddings from SQLUser.testtable
    )
    Do AssertSQLExecutionIsOK(SQLCODE)
    Do $$$AssertTrue(##class(%Library.Vector).IsValid(embeddings), "embeddings is valid")

    Return $$$OK
}

Method AssertSQLExecutionIsOK(pSQLCODE)
{
    Do $$$AssertTrue((pSQLCODE = 0) || (pSQLCODE = 100), "SQL code is 0 or 100 (OK); got "_pSQLCODE)
}

}
