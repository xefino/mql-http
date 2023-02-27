#property copyright "Xefino"
#property version   "1.03"
#property strict

#include "Response.mqh"
#include "WebCommon.mqh"

// Define the components of the user agent
#define APP_NAME        "Xefino"
#define APP_VERSION     "1.03"
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
   //    url:        The URL we're sending the request to (should be preceded with http or https)
   //    referrer:   A referrer to set on the request, defaults to NULL
   HttpRequester(const string verb, const string url, const string referrer = NULL);

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
//    url:        The URL we're sending the request to (should be preceded with http or https)
//    referrer:   A referrer to set on the request, defaults to NULL
HttpRequester::HttpRequester(const string verb, const string url, const string referrer = NULL) {
   m_ready = false;
   
   InternetAttemptConnect(0);
   
   // First, report to Windows the user agent that we'll request HTTP data with. If this fails
   // then return an error
   int flags = INTERNET_OPEN_TYPE_DIRECT | INTERNET_OPEN_TYPE_PRECONFIG | INTERNET_FLAG_NO_CACHE_WRITE;
   m_open_handle = InternetOpenW(GetUserAgentString(), flags, NULL, NULL, 0);
   if (m_open_handle == INTERNET_INVALID_HANDLE) {
      #ifdef HTTP_LIBRARY_LOGGING
         int errCode = GetLastError();
         Print("Failed to create user-agent, error: ", errCode);
      #endif
      SetUserError(INTERNET_OPEN_FAILED_ERROR);
      return;
   }
   
   // Next, get the port from the URL; if the protocol wasn't set to HTTP or HTTPS then 
   // return an error
   int port;
   if (StringSubstr(url, 0, 5) == INTERNET_PROTOCOL_HTTPS) {
      port = INTERNET_DEFAULT_HTTPS_PORT;
      flags |= INTERNET_FLAG_SECURE;
   } else if (StringSubstr(url, 0, 4) == INTERNET_PROTOCOL_HTTP) {
      port = INTERNET_DEFAULT_HTTP_PORT;
   } else {
      #ifdef HTTP_LIBRARY_LOGGING
         Print("Invalid protocol present on URL ", url);
      #endif
      SetUserError(INTERNET_PROTOCOL_INVALID_ERROR);
      return;
   }
   
   // Now, attempt to create an intenrnet connection to the URL at the desired port;
   // if this fails then return an error
   m_session_handle = InternetConnectW(m_open_handle, url, port, NULL, NULL, 
      INTERNET_SERVICE_HTTP, flags, 1);
   if (m_session_handle == INTERNET_INVALID_HANDLE) {
      #ifdef HTTP_LIBRARY_LOGGING
         int errCode = GetLastError();
         PrintFormat("Failed to connect to %s:%d, error: %d", url, port, errCode);
      #endif
      SetUserError(INTERNET_CONNECT_FAILED_ERROR);
      return;
   }
   
   // Finally, open the HTTP request with the session variable, verb and URL; if this fails
   // then log and return an error
   string accepts[];
   m_request_handle = HttpOpenRequestW(m_session_handle, verb, url, NULL, referrer, 
      accepts, INTERNET_FLAG_NO_UI, 1);
   if (m_request_handle == INTERNET_INVALID_HANDLE) {
      #ifdef HTTP_LIBRARY_LOGGING
         int errCode = GetLastError();
         PrintFormat("Failed to create %s HTTP request to %s:%d, error: %d", 
            verb, url, port, errCode);
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
   if (!HttpSendRequestW(m_request_handle, NULL, 0, body, StringLen(body))) {
      
      // First, attempt to read the error and check that it isn't zero. There is a chance that
      // we need to write additional data so, in this case we'll continue on. Otherwise, we'll
      // log the failure and return an error
      int errCode = GetLastError();
      if (errCode != 0) {
         #ifdef HTTP_LIBRARY_LOGGING
            Print("Failed to send HTTP request, error: ", errCode);
         #endif
         return INTERNET_SEND_FAILED_ERROR;
      }
      
      // Next, check if we have query data available and, if we do, attempt to write data to an
      // internet file. If the query fails because there are no more files then do nothing; otherwise,
      // log the error and return
      int data;
      if (!InternetQueryDataAvailable(m_request_handle, data, 0, 0)) {
         int errCode = GetLastError();
         if (errCode != ERROR_NO_MORE_FILES) {
            #ifdef HTTP_LIBRARY_LOGGING
               Print("Failed to check if more data was available to send, error: ", errCode);
            #endif
            return INTERNET_SEND_FAILED_ERROR;
         }
      } else if (!InternetWriteFile(m_request_handle, body, StringLen(body), data)) {
         #ifdef HTTP_LIBRARY_LOGGING
            int errCode = GetLastError();
            Print("Failed to write the remaining data to the HTTP request, error: ", errCode);
         #endif
         return INTERNET_SEND_FAILED_ERROR;
      }
      
      // Finally, end the HTTP request; if this fails then log the error and return
      if (!HttpEndRequest(m_request_handle, NULL, 0, 0)) {
         #ifdef HTTP_LIBRARY_LOGGING
            int errCode = GetLastError();
            Print("Failed to end the HTTP request, error: ", errCode);
         #endif
         return INTERNET_SEND_FAILED_ERROR;
      }
   }
   
   // Now, attempt to read the response data into our response object
   int bytesRead;
   string buffer;
   while (InternetReadFile(m_request_handle, buffer, INTERNET_BUFFER_LENGTH, bytesRead) && bytesRead > 0) {
      response.Body += buffer;
      buffer = "";
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
   if (!HttpQueryInfo(m_request_handle, HTTP_QUERY_STATUS_CODE | HTTP_QUERY_FLAG_NUMBER, 
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