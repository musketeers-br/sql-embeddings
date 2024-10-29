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
    import iris

    logger = logging.getLogger(__name__)
    settings = iris.cls(__name__).GetLoggerSettings()
    logLevel = settings["log_level"]
    logFileName = settings["log_file_name"]
    logging.basicConfig(filename=logFileName, level=logLevel, format='%(asctime)s - %(levelname)s - %(message)s')

    return logger
}

ClassMethod GetLoggerSettings() As %SYS.Python [ Language = python ]
{
    import os
    import logging

    logLevel = os.environ.get('SQLEMBEDDINGS_LOGGER_SETTINGS_LOG_LEVEL', logging.INFO)
    try:
        logLevel = getattr(logging, logLevel)
    except:
        logLevel = logging.INFO

    logFileName = os.environ.get('SQLEMBEDDINGS_LOGGER_SETTINGS_LOG_FILE_NAME', '/tmp/sql-embeddings.log')
    
    return {
        "log_level": logLevel,
        "log_file_name": logFileName
    }
}

/// Logs a message to the global log and the logger for this class.
/// 
/// @param message The message to be logged.
ClassMethod Info(message As %String) [ Language = python ]
{
    import iris
    logger = iris.cls(__name__).GetLogger()
    logger.info(message)
}

ClassMethod Debug(message As %String) [ Language = python ]
{
    import iris
    logger = iris.cls(__name__).GetLogger()
    logger.debug(message)
}

ClassMethod Error(message As %String) [ Language = python ]
{
    import iris
    logger = iris.cls(__name__).GetLogger()
    logger.error(message)
}

}
