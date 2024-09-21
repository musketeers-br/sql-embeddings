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
    Do ##class(dc.musketeersbr.sqlembeddings.Socket).SaveCurrentProcessID($JOB)
    Do ##class(dc.musketeersbr.sqlembeddings.Socket).SaveCurrentPort(pPort)
    Do ..StartServerPy(pPort)
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
        print("\nServer shutting down gracefully...")
        server_socket.close()
        sys.exit(0)

    def load_provider(providerName, modelName, loadedProviders):
        if providerName in loadedProviders:
            print(f"Model '{providerName}' already loaded, skipping...")
            model = loadedProviders[providerName]
        else:
            # todo: import the model from parameters (model and provider) on request formatted in json
            print("Model '{providerName}' not loaded, loading...")
            providerClassName = iris.cls("dc.musketeersbr.sqlembeddings.Embeddings").GetEmbeddingsProvider(providerName)
            print(f"Selected providerClassName: {providerClassName}")
            model = iris.cls(providerClassName).LoadEmbeddingModel(modelName)
            print(f"Selected model: {model}")
            loadedProviders[providerName] = model

        return model, loadedProviders

    def get_provider_from_request(request, loadedProviders):
        modelFQN = request['modelFQN']
        providerName = modelFQN.split('/')[0]
        modelName = '/'.join(modelFQN.split('/')[1:])
        print(f"Selected modelFQN: {modelFQN}")
        print(f"Selected providerName: {providerName}")
        print(f"Selected model: {modelName}")

        model, _ = load_provider(providerName, modelName, loadedProviders)
        providerClassName = iris.cls("dc.musketeersbr.sqlembeddings.Embeddings").GetEmbeddingsProvider(providerName)
        return iris.cls(providerClassName), model

    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)

    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind(('localhost', port))
    server_socket.listen(5)
    #; server_socket.timeout(10)

    providerClassName = 'fastembed'
    modelName = 'BAAI/bge-small-en-v1.5'
    loadedProviders = {}
    model = None
    error_msg = None
    try:
        model, loadedProviders = load_provider(providerClassName, modelName, loadedProviders)
    except Exception as e:
        error_msg = f"Error loading model: {e}"

    print(f"Server listening on port {port}...")

    try:
        while True:
            client_socket, addr = server_socket.accept()
            print(f"Connection from {addr}")

            # if there was an error loading the model, send an error message
            if error_msg is not None:
                # todo: structure the error message in json
                request = json.dumps({'error': error_msg})
                print(f"Sending error: {request}")
                client_socket.sendall(request.encode('utf-8'))
            else:
                request = client_socket.recv(99999)
                request = request.decode('utf-8')
                if request:
                    print(f"Received: {request}")

                    request = json.loads(request)
                    document = request['document']
                    provider, model = get_provider_from_request(request, loadedProviders)
                    print(f"Selected provider: {provider}")
                    embeddings_string = provider.ExecuteEmbeddings(document, model)
                    #; embeddings_string = embeddings_string.encode('utf-8')
                    response = json.dumps({'embeddings': embeddings_string})
                    client_socket.sendall(response.encode('utf-8'))
                    print(f"Response sent.")

            client_socket.close()

    except Exception as e:
        print(f"Error: {e}")

    finally:
        server_socket.close()
        print("Server closed.")
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
    Set embeddings = ..StartClientPy(pMessage, pServer, pPort)
    Return embeddings
}

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
        print("\nClient shutting down gracefully...")
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
        print(f"Available port: {available_port}")
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
        print(f"Server is {'up' if result == 0 else 'down'} on port {port}.")
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
        pid = iris.cls("dc.musketeersbr.sqlembeddings.Socket").GetCurrentProcessID()
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
        curr_port = iris.cls("dc.musketeersbr.sqlembeddings.Socket").GetCurrentPort()
        curr_pid = iris.cls("dc.musketeersbr.sqlembeddings.Socket").GetCurrentProcessID()
        if curr_pid:
            print(f"Killing server on port {curr_port} and pid {curr_pid}...")
            kill_server()

        print(f"Starting a new server on port {port}...")
        pid = iris.cls("dc.musketeersbr.sqlembeddings.Socket").StartServerBackground(port)
        #; iris.cls("dc.musketeersbr.sqlembeddings.Socket").SaveCurrentProcessID(pid)
        #; iris.cls("dc.musketeersbr.sqlembeddings.Socket").SaveCurrentPort(port)

        #; for i in range(60):
        #;     print(f"Waiting for server to start on port {port}...")
        #;     if not check_if_server_is_down(server, port):
        #;         print(f"Server on port {port} is up.")
        #;         break
        #;     time.sleep(1)
        time.sleep(.5)

    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)

    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    #; client_socket.settimeout(10)

    try:
        if str(port) == '':
            print("No port specified, using current port...")
            port = iris.cls("dc.musketeersbr.sqlembeddings.Socket").GetCurrentPort()
            print(f"Current port: {port}")

        if str(port) == '':
            print("No port specified, using default port...")
            port = get_available_port()
            print(f"Selected port: {port}")

        print("Starting the client on port " + str(port) + "...")

        if check_if_server_is_down(server, port):
            start_new_server(port)

        client_socket.connect((server, port))
        # todo: structure the message in json with model and provider
        document = message._Get('document')
        modelName = message._Get('modelName')
        request = json.dumps({'document': document, 'modelFQN': modelName})
        client_socket.sendall(request.encode('utf-8'))
        response = client_socket.recv(999999).decode('utf-8')
        response = json.loads(response)

        # todo: read the error expecting a message in json
        # check if the server response is about an error
        if "error" in response:
            # raise an exception with the error message
            raise Exception(response["error"])

        return response["embeddings"]

    except ConnectionRefusedError:
        print("[Error] Connection refused: Server may be down or not accepting connections.")
        start_new_server(port)
        return iris.cls("dc.musketeersbr.sqlembeddings.Socket").StartClientPy(message, server, port)

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

}
