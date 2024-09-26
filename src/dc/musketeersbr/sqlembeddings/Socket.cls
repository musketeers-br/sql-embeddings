/// Handle a client/server interface for run embeddings models.
/// Create to handle slow imports as described in https://stackoverflow.com/a/78053521
Class dc.musketeersbr.sqlembeddings.Socket Extends %RegisteredObject
{

/// Start the embeddings services server on the given port.
/// 
/// This method starts a new process running the server on the given port.
/// The server will listen for incoming connections and process any requests
/// it receives.
/// 
/// @param pPort The port number to listen on.
ClassMethod StartServer(pPort As %Integer)
{
    Try {
        Do ##class(dc.musketeersbr.sqlembeddings.Socket).SaveCurrentProcessID($JOB)
        Do ##class(dc.musketeersbr.sqlembeddings.Socket).SaveCurrentPort(pPort)
        Do ..StartServerPy(pPort)
    } Catch e {
        Set error = $System.Status.GetErrorText(e.AsStatus())
        Do ##class(dc.musketeersbr.sqlembeddings.Socket).LogServer(error, "ERROR")
        Throw e
    }
}

/// Start the embeddings services server in the background on the given port.
/// This method forks a new process to run the server and returns the process ID.
/// @param pPort The port number to listen on.
/// @return The process ID of the server process.
ClassMethod StartServerBackground(pPort As %Integer) As %Integer [ Private ]
{
    Job ..StartServer(pPort)
    Set pID = $ZCHILD
    Return pID
}

/// Starts a server in Python to handle incoming connections and generate embeddings using a specified model.
/// The server listens on the specified port and responds to incoming connections by generating embeddings
/// for the received string using the specified model.
/// 
/// This is the actual embeddings server implementation in Python using its socket library.
/// 
/// @param port The port number to listen on.
ClassMethod StartServerPy(port As %Integer) [ Language = python, Private ]
{
    import socket
    import signal
    import sys
    import iris
    import json

    def signal_handler(sig, frame):
        """
        Signal handler to shut down the server gracefully when a signal is received.

        :param sig: The signal number.
        :param frame: The current stack frame.
        :return: None
        """
        iris.cls(__name__).LogServer("Server shutting down gracefully...", "INFO")
        server_socket.close()
        sys.exit(0)

    def load_provider(providerName, modelName, loadedProviders):
        if providerName in loadedProviders:
            iris.cls(__name__).LogServer(f"Model '{providerName}' already loaded, skipping...")
            model = loadedProviders[providerName]
        else:
            iris.cls(__name__).LogServer(f"Model '{providerName}' not loaded, loading...")
            providerClassName = iris.cls("dc.musketeersbr.sqlembeddings.Embeddings").GetEmbeddingsProvider(providerName)
            iris.cls(__name__).LogServer(f"Selected providerClassName: {providerClassName}")
            model = iris.cls(providerClassName).LoadEmbeddingModel(modelName, providerClassName)
            iris.cls(__name__).LogServer(f"Selected model: {model}")
            loadedProviders[providerName] = model

        return model, loadedProviders

    def get_provider_from_request(request, loadedProviders):
        modelFQN = request['modelFQN']
        providerName = modelFQN.split('/')[0]
        modelName = '/'.join(modelFQN.split('/')[1:])
        iris.cls(__name__).LogServer(f"Selected modelFQN: {modelFQN}")
        iris.cls(__name__).LogServer(f"Selected providerName: {providerName}")
        iris.cls(__name__).LogServer(f"Selected model: {modelName}")

        model, _ = load_provider(providerName, modelName, loadedProviders)
        providerClassName = iris.cls("dc.musketeersbr.sqlembeddings.Embeddings").GetEmbeddingsProvider(providerName)
        return iris.cls(providerClassName), model, modelName

    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)

    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind(('localhost', port))
    server_socket.listen(5)

    loadedProviders = {}
    error_msg = None

    iris.cls(__name__).LogServer(f"Server listening on port {port}...", "INFO")

    try:
        while True:
            client_socket, addr = server_socket.accept()
            iris.cls(__name__).LogServer(f"Connection from {addr}")

            # if there was an error loading the model, send an error message
            if error_msg is not None:
                request = json.dumps({'error': error_msg})
                iris.cls(__name__).LogServer(f"Sending error: {request}")
                client_socket.sendall(request.encode('utf-8'))
            else:
                request = client_socket.recv(99999)
                request = request.decode('utf-8')
                if request:
                    iris.cls(__name__).LogServer(f"Received: {request}")

                    request = json.loads(request)
                    document = request['document']
                    provider, model, modelName = get_provider_from_request(request, loadedProviders)
                    iris.cls(__name__).LogServer(f"Selected provider: {provider}")
                    #; embeddings_string = provider.ExecuteEmbeddings(document, model)
                    embeddings_string = provider.GetEmbeddings(document, model, modelName)
                    #; embeddings_string = embeddings_string.encode('utf-8')
                    response = json.dumps({'embeddings': embeddings_string})
                    client_socket.sendall(response.encode('utf-8'))
                    iris.cls(__name__).LogServer(f"Response sent.")

            client_socket.close()

    except Exception as e:
        iris.cls(__name__).LogServer(f"Error: {e}", "ERROR")
        error_msg = str(e)
        request = json.dumps({'error': error_msg})
        iris.cls(__name__).LogServer(f"Sending error: {request}")
        client_socket.sendall(request.encode('utf-8'))

    finally:
        server_socket.close()
        iris.cls(__name__).LogServer("Server closed.", "INFO")
}

/// Starts a client to connect to the embeddings services server and send a message.
/// 
/// This method starts a new client process to connect to the server at the given
/// host and port, and sends the given message to the server.
/// The method returns the response from the server as a string.
/// 
/// @param pServer The host name or IP address of the server.
/// @param pPort The port number of the server.
/// @param pMessage The message to be sent to the server.
/// @return The response from the server as a string.
ClassMethod StartClient(pMessage As %DynamicObject, pServer As %String = "localhost", pPort As %Integer = "") As %String
{
    Try {
        Set embeddings = ..StartClientPy(pMessage, pServer, pPort)
    } Catch e {
        Set error = $System.Status.GetErrorText(e.AsStatus())
        Do ##class(dc.musketeersbr.sqlembeddings.Socket).LogClient(error, "ERROR")
        Throw e
    }
    Return embeddings
}

/// Starts a client to send a request to the server to generate embeddings for the given message.
/// 
/// This method starts a client to send a request to the server to generate embeddings for the given message.
/// The client will connect to the given server and port, and send the message as a JSON-serialized object.
/// The server will generate the embeddings and return them as a JSON-serialized object, which will be deserialized
/// and returned as a string.
/// 
/// @param message The message to be embedded as a %DynamicObject.
/// @param server The server host name or IP address.
/// @param port The port number to connect to.
/// @return The embeddings as a string.
ClassMethod StartClientPy(message As %DynamicObject, server As %String = "localhost", port As %Integer = "") As %String [ Language = python ]
{
    import socket
    import os
    import signal
    import sys
    import time
    import iris
    import json

    def signal_handler(sig, frame):
        """
        Signal handler to catch SIGINT and SIGTERM and perform a clean shutdown.

        :param sig: The signal number that was received.
        :param frame: The current stack frame.
        """
        iris.cls(__name__).LogClient("Client shutting down gracefully...", "INFO")
        client_socket.close()
        sys.exit(0)

    def get_available_port():
        """
        Finds an available port on localhost.

        Uses the socket module to create a socket, bind it to localhost with port 0,
        and then retrieve the port number that the operating system assigned.

        :return: The port number that is available.
        """
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.bind(('', 0))
        available_port = s.getsockname()[1]
        s.close()
        iris.cls(__name__).LogClient(f"Available port: {available_port}")
        return available_port

    def check_if_server_is_down(server, port):
        """
        Checks if the server is down by attempting a connection to the given server and port.

        Args:
            server (str): The server host name or IP address.
            port (int): The port number.

        Returns:
            bool: True if the server is down, False otherwise.
        """
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex((server, port))
        iris.cls(__name__).LogClient(f"Server is {'up' if result == 0 else 'down'} on port {port}.")
        return result != 0

    def kill_server():
        """
        Kill the current server process.

        This method attempts to kill the current server process by sending a
        SIGINT signal to the process with the ID stored in the
        `dc.musketeersbr.sqlembeddings.Socket` class. If the process does not
        exist, this method will do nothing.

        Returns:
            None
        """
        pid = iris.cls(__name__).GetCurrentProcessID()
        try:
            os.kill(pid, signal.SIGINT)
        except:
            pass

    """
    Starts a new server in the background on the given port.

    If there is already a server running, it will be killed first.

    :param port: The port to start the server on.
    :return: None
    """
    def start_new_server(port):
        curr_port = iris.cls(__name__).GetCurrentPort()
        curr_pid = iris.cls(__name__).GetCurrentProcessID()
        if curr_pid:
            iris.cls(__name__).LogClient(f"Killing server on port {curr_port} and pid {curr_pid}...")
            kill_server()

        iris.cls(__name__).LogClient(f"Starting a new server on port {port}...")
        pid = iris.cls(__name__).StartServerBackground(port)
        #; iris.cls(__name__).SaveCurrentProcessID(pid)
        #; iris.cls(__name__).SaveCurrentPort(port)

        time.sleep(.5)

    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)

    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    #; client_socket.settimeout(10)

    try:
        if str(port) == '':
            iris.cls(__name__).LogClient("No port specified, using current port...")
            port = iris.cls(__name__).GetCurrentPort()
            iris.cls(__name__).LogClient(f"Current port: {port}")

        if str(port) == '':
            iris.cls(__name__).LogClient("No port specified, using default port...")
            port = get_available_port()
            iris.cls(__name__).LogClient(f"Selected port: {port}")

        iris.cls(__name__).LogClient("Starting the client on port " + str(port) + "...")

        if check_if_server_is_down(server, port):
            start_new_server(port)

        client_socket.connect((server, port))
        document = message._Get('document')
        modelName = message._Get('modelName')
        request = json.dumps({'document': document, 'modelFQN': modelName})
        client_socket.sendall(request.encode('utf-8'))
        response = client_socket.recv(999999).decode('utf-8')
        response = json.loads(response)

        # check if the server response is about an error
        if "error" in response:
            # raise an exception with the error message
            raise Exception(response["error"])

        return response["embeddings"]

    except ConnectionRefusedError:
        iris.cls(__name__).LogClient("[Error] Connection refused: Server may be down or not accepting connections.", "ERROR")
        start_new_server(port)
        return iris.cls(__name__).StartClientPy(message, server, port)

    finally:
        client_socket.close()
}

/// Saves the current port number to the IRIS temporary storage.
/// @param pPort The current port number.
ClassMethod SaveCurrentPort(pPort As %Integer)
{
    Set ^IRIS.Temp("MusketeersBR","SQLEMBEDDINGS","PORT") = pPort
}

/// Retrieves the current port number from the IRIS temporary storage.
/// @return The current port number.
ClassMethod GetCurrentPort() As %Integer
{
    Return $GET(^IRIS.Temp("MusketeersBR","SQLEMBEDDINGS","PORT"))
}

/// Saves the current process ID to the IRIS temporary storage.
/// @param pProcessID The current process ID.
ClassMethod SaveCurrentProcessID(pProcessID As %Integer)
{
    Set ^IRIS.Temp("MusketeersBR","SQLEMBEDDINGS","PROCESSID") = pProcessID
}

/// Retrieves the current process ID from the IRIS temporary storage.
/// @return The current process ID.
ClassMethod GetCurrentProcessID() As %Integer
{
    Return $GET(^IRIS.Temp("MusketeersBR","SQLEMBEDDINGS","PROCESSID"))
}

/// Logs a message to the server log.
/// 
/// @param message The message to be logged.
ClassMethod LogServer(message As %String, mode As %String = "DEBUG") [ Language = python ]
{
    import iris
    if mode == "DEBUG":
        iris.cls("dc.musketeersbr.sqlembeddings.Logger").Debug(f"[Server] {message}")
    elif mode == "ERROR":
        iris.cls("dc.musketeersbr.sqlembeddings.Logger").Error(f"[Server] {message}")
    else:
        iris.cls("dc.musketeersbr.sqlembeddings.Logger").Info(f"[Server] {message}")
}

/// Logs a message from the client.
/// 
/// This method logs a message from the client using the iris Log method.
/// The message will be prefixed with "[Client] " to indicate that it
/// came from the client.
/// 
/// @param message The message to be logged.
ClassMethod LogClient(message As %String, mode As %String = "DEBUG") [ Language = python ]
{
    import iris
    if mode == "DEBUG":
        iris.cls("dc.musketeersbr.sqlembeddings.Logger").Debug(f"[Client] {message}")
    elif mode == "ERROR":
        iris.cls("dc.musketeersbr.sqlembeddings.Logger").Error(f"[Client] {message}")
    else:
        iris.cls("dc.musketeersbr.sqlembeddings.Logger").Info(f"[Client] {message}")
}

}
