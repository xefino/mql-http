#property copyright "Xefino"
#property version   "1.06"
#property strict

#include "Response.mqh"
#include "WebCommon.mqh"

// Define the components of the user agent
#define APP_NAME        "Xefino"
#define APP_VERSION     "1.06"
#ifdef __WIN64__
   #define USER_AGENT   "Windows 64-bit"
#else
   #define USER_AGENT   "Windows 32-bit"
#endif

// HttpRequester
// Allows for the structured request of HTTP resources
class HttpRequester {
private:

   int   m_open_handle;    // A handle pointing to the this open connection
   int   m_session_handle; // A handle pointing to the session
   int   m_request_handle; // A handle pointing to the request
   bool  m_ready;          // Whether or not the request is ready
   
public:

   // Creates a new instance of an HTTP requester; if this fails then the user error will be set
   //    verb:       The REST verb to associate with this request (POST, GET, PUT, DELETE, etc.)
   //    host:       The host name of the server we're connecting to
   //    resource:   The path to the resource we're requesting
   //    port:       The port number we want to send the request to
   //    secure:     Whether or not the connection should be secured with a TLS/SSL certificate
   //    referrer:   A referrer to set on the request, defaults to NULL
   HttpRequester(const string verb, const string host, const string resource, const int port,
      const bool secure, const string referrer = NULL);

   // Destroys this instance of the HTTP requester, releasing all the resources controlled by this request
   ~HttpRequester();

   // Adds a header to the HTTP requester. If this fails then a non-zero error code will be returned.
   // Otherwise, this function will return zero.
   //    name:       The name of the header
   //    value:      The value to set to the header
   //    coalesce:   True to allow multiple header values to be associated with the same header name.
   //                False, to overwrite the existing value if the header name already exists
   int AddHeader(const string name, const string value, const bool coalesce) const;
   
   // Sends the HTTP requester to the server, with the request body provided. I:f this function fails then
   // a non-zero error will be returned. Otherwise, this function will return zero.
   //    body:       The request body to send with the request
   //    response:   The HTTP resposne that will contain the status code and response body
   int SendRequest(const string body, HttpResponse &response);
};

// Creates a new instance of an HTTP requester; if this fails then the user error will be set
//    verb:       The REST verb to associate with this request (POST, GET, PUT, DELETE, etc.)
//    host:       The host name of the server we're connecting to
//    resource:   The path to the resource we're requesting
//    port:       The port number we want to send the request to
//    secure:     Whether or not the connection should be secured with a TLS/SSL certificate
//    referrer:   A referrer to set on the request, defaults to NULL
HttpRequester::HttpRequester(const string verb, const string host, const string resource, 
   const int port, const bool secure, const string referrer = NULL) {
   m_ready = false;
   ResetLastError();
      
   // First, report to Windows the user agent that we'll request HTTP data with. If this fails
   // then return an error
   int flags = INTERNET_OPEN_TYPE_PRECONFIG;
   m_open_handle = InternetOpenW(GetUserAgentString(), flags, NULL, NULL, 0);
   if (m_open_handle == INTERNET_INVALID_HANDLE) {
      #ifdef HTTP_LIBRARY_LOGGING
         int errCode = GetLastError();
         Print("Failed to create user-agent, error: ", errCode);
      #endif
      SetUserError(INTERNET_OPEN_FAILED_ERROR);
      return;
   }
   
   // Next, attempt to create an intenrnet connection to the URL at the desired port;
   // if this fails then return an error
   m_session_handle = InternetConnectW(m_open_handle, host, port, "", "", INTERNET_SERVICE_HTTP, flags, 0);
   if (m_session_handle == INTERNET_INVALID_HANDLE) {
      #ifdef HTTP_LIBRARY_LOGGING
         int errCode = GetLastError();
         PrintFormat("Failed to connect to %s:%d, error: %d", host, port, errCode);
      #endif
      SetUserError(INTERNET_CONNECT_FAILED_ERROR);
      return;
   }
   
   // Now, if we want a secure connection then add the secure flag to the connection
   if (secure) {
      flags |= INTERNET_FLAG_SECURE;
   }
   
   // Finally, open the HTTP request with the session variable, verb and URL; if this fails
   // then log and return an error
   string accepts[];
   m_request_handle = HttpOpenRequestW(m_session_handle, verb, resource, NULL, referrer, 
      accepts, flags, 0);
   if (m_request_handle == INTERNET_INVALID_HANDLE) {
      #ifdef HTTP_LIBRARY_LOGGING
         int errCode = GetLastError();
         PrintFormat("Failed to create %s HTTP request to %s/%s against port %d, error: %d", 
            verb, host, resource, port, errCode);
      #endif
      SetUserError(INTERNET_OPEN_REQUEST_FAILED_ERROR);
      return;
   }
   
   m_ready = true;
}

// Destroys this instance of the HTTP requester, releasing all the resources controlled by this request
HttpRequester::~HttpRequester() {
   
   // First, if the request handle is not invalid then attempt to close the handle
   if (m_request_handle != INTERNET_INVALID_HANDLE) {
      InternetCloseHandle(m_request_handle);
   }
   
   // Next, if the session handle is not invalid then attempt to close the handle
   if (m_session_handle != INTERNET_INVALID_HANDLE) {
      InternetCloseHandle(m_session_handle);
   }
   
   // Finally, if the open-handle is not invalid then attempt to close the handle
   if (m_open_handle != INTERNET_INVALID_HANDLE) {
      InternetCloseHandle(m_open_handle);
   }
}

// Adds a header to the HTTP requester. If this fails then a non-zero error code will be returned.
// Otherwise, this function will return zero.
//    name:       The name of the header
//    value:      The value to set to the header
//    coalesce:   True to allow multiple header values to be associated with the same header name.
//                False, to overwrite the existing value if the header name already exists
int HttpRequester::AddHeader(const string name, const string value, const bool coalesce) const {
   
   // First, check that the request is read. If it isn't then return an erorr
   if (!m_ready) {
      return INTERNET_REQUEST_NOT_READY;
   }
   
   // Next, create the header from the name and value
   string header = name + ":" + value;

   // Now, get the code. If we want to coalesce the header then set the coalesce flag. Otherwise,
   // set the replace flag. We'll set the add flag as well
   uint code = HTTP_ADDREQ_FLAG_ADD;
   if (coalesce) {
      code |= HTTP_ADDREQ_FLAG_COALESCE;
   } else {
      code |= HTTP_ADDREQ_FLAG_REPLACE;
   }

   // Finally, attempt to add the request header to the HTTP request; if this fails then 
   // log the error and return an error code
   if (!HttpAddRequestHeadersW(m_request_handle, header, -1, code)) {
      #ifdef HTTP_LIBRARY_LOGGING
         int errCode = GetLastError();
         PrintFormat("Failed to add header %s to HTTP request, error: %d", header, errCode);
      #endif
      return INTERNET_ADD_HEADER_FAILED_ERROR;
   }
   
   return 0;
}

// Sends the HTTP requester to the server, with the request body provided. I:f this function fails then
// a non-zero error will be returned. Otherwise, this function will return zero.
//    body:       The request body to send with the request
//    response:   The HTTP resposne that will contain the status code and response body
int HttpRequester::SendRequest(const string body, HttpResponse &response) {
   
   // First, check that the request is ready to send. If it's not then return an error
   if (!m_ready) {
      return INTERNET_REQUEST_NOT_READY;
   }

   // Next, attempt to send the request to the server; if this fails then return an error
   char reqBuffer[];
   int length = StringToCharArray(body, reqBuffer);
   if (!HttpSendRequestW(m_request_handle, NULL, 0, reqBuffer, length)) {
      #ifdef HTTP_LIBRARY_LOGGING
         int errCode = GetLastError();
         Print("Failed to send HTTP request, error: ", errCode);
      #endif
      return INTERNET_SEND_FAILED_ERROR;
   }
   
   // Now, attempt to read the response data into our response object
   int bytesRead;
   char buffer[];
   ArrayResize(buffer, INTERNET_BUFFER_LENGTH);
   while (InternetReadFile(m_request_handle, buffer, INTERNET_BUFFER_LENGTH, bytesRead) && bytesRead > 0) {
      response.Body += CharArrayToString(buffer);
      ArrayInitialize(buffer, 0);
   }
   
   // Check if there was data left. If there was then the buffer did not finish reading which implies
   // that the read function failed; so return an error
   if (bytesRead > 0) {
      #ifdef HTTP_LIBRARY_LOGGING
         int errCode = GetLastError();
         PrintFormat("Failed to send HTTP request, error: %d", errCode);
      #endif
      return INTERNET_RECEIVE_FAILED_ERROR;
   }
   
   // Finally, extract the status code from the response; if this fails then return an error
   int index;
   int size = sizeof(response.StatusCode);
   if (!HttpQueryInfoW(m_request_handle, HTTP_QUERY_STATUS_CODE | HTTP_QUERY_FLAG_NUMBER, 
      response.StatusCode, size, index)) {
      #ifdef HTTP_LIBRARY_LOGGING
         int errCode = GetLastError();
         PrintFormat("Failed to get status code from HTTP response, error: %d", errCode);
      #endif
      return INTERNET_READ_RESP_FAILED_ERROR;
   }
   
   return 0;
}

// Helper function that gets the user agent string
string GetUserAgentString() {
    return StringFormat("%s/%s (%s; Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " + 
      "(KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36)", APP_NAME, APP_VERSION, USER_AGENT);
}