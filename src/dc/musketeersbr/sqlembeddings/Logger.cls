Class dc.musketeersbr.sqlembeddings.Logger Extends %RegisteredObject
{

/// Gets a logger instance for logging information.
/// 
/// This method creates a logger instance and sets up basic logging configuration
/// to log to a file at /tmp/sql-embeddings.log with level INFO.
/// 
/// @return A logger instance.
ClassMethod GetLogger() As %SYS.Python [ Language = python ]
{
    import logging

    logger = logging.getLogger(__name__)
    # todo: set up logging level from environment variable and default it to INFO
    logging.basicConfig(filename='/tmp/sql-embeddings.log', level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

    return logger
}

/// Logs a message to the global log and the logger for this class.
/// 
/// @param message The message to be logged.
ClassMethod Info(message As %String) [ Language = python ]
{
    import iris
    logger = iris.cls(__name__).GetLogger()
    logger.info(message)
    print(message)
    #; iris.cls(__name__).LogToGlobal(message)
}

ClassMethod Debug(message As %String) [ Language = python ]
{
    import iris
    logger = iris.cls(__name__).GetLogger()
    logger.debug(message)
    #; print(message)
    #; iris.cls(__name__).LogToGlobal(message)
}

ClassMethod Error(message As %String) [ Language = python ]
{
    import iris
    logger = iris.cls(__name__).GetLogger()
    logger.error(message)
    print(message)
    #; iris.cls(__name__).LogToGlobal(message)
}

/// Logs a message to the global ^IRIS.Temp("MusketeersBR","SQLEMBEDDINGS","LOG") array.
/// 
/// This method is used to log messages from the embeddings services.
/// The messages are stored in a global array and can be accessed later.
/// 
/// @param pMessage The message to be logged.
ClassMethod LogToGlobal(pMessage As %String)
{
    Set ^IRIS.Temp("MusketeersBR","SQLEMBEDDINGS","LOG",$I(^IRIS.Temp("MusketeersBR","SQLEMBEDDINGS","LOG"))) = pMessage
}

}
