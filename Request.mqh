#property copyright "Xefino"
#property version   "1.00"
#property strict

#include "WebCommon.mqh"

// HttpResponse
// Contains information returned from an HTTP request
struct HttpResponse {
   int      StatusCode;
   string   Body;
}

// HttpRequest
// Allows for the structured request of HTTP resources
class HttpRequest {
private:

   int m_open_handle;      // A handle pointing to the this open connection
   int m_session_handle;   // A handle pointing to the session
   int m_request_handle;   // A handle pointing to the request
   bool m_ready;           // Whether or not the request is ready
   
public:

   // Creates a new instance of an HTTP request; if this fails then the user error will be set
   //    verb:       The REST verb to associate with this request (POST, GET, PUT, DELETE, etc.)
   //    url:        The URL we're sending the request to (should be preceded with http or https)
   //    accept:     A list of accept headers we'll send with the request
   //    referrer:   A referrer to set on the request, defaults to NULL
   HttpRequest(const string verb, const string url, const string &accept[], 
      const string referrer = NULL);

   // Destroys this instance of the HTTP request, releasing all the resources controlled by this request
   ~HttpRequest();

   // Adds a header to the HTTP request. If this fails then a non-zero error code will be returned.
   // Otherwise, this function will return zero.
   //    name:       The name of the header
   //    value:      The value to set to the header
   //    coalesce:   True to allow multiple header values to be associated with the same header name.
   //                False, to overwrite the existing value if the header name already exists
   int AddHeader(const string name, const string value, const bool coalesce) const;
   
   // Sends the HTTP request to the server, with the request body provided. I:f this function fails then
   // a non-zero error will be returned. Otherwise, this function will return zero.
   //    body:       The request body to send with the request
   //    response:   The HTTP resposne that will contain the status code and response body
   int SendRequest(const string body, HttpResponse &response);
}

// Creates a new instance of an HTTP request; if this fails then the user error will be set
//    verb:       The REST verb to associate with this request (POST, GET, PUT, DELETE, etc.)
//    url:        The URL we're sending the request to (should be preceded with http or https)
//    accept:     A list of accept headers we'll send with the request
//    referrer:   A referrer to set on the request, defaults to NULL
HttpRequest::HttpRequest(const string verb, const string url, const string &accept[], 
   const string referrer = NULL) {
   m_ready = false;
   
   // First, report to Windows the user agent that we'll request HTTP data with. If this fails
   // then return an error
   m_open_handle = InternetOpenW("Xefino OrderSend", INTERNET_OPEN_TYPE_PRECONFIG, 
      NULL, NULL, INTERNET_FLAG_NO_UI);
   if (handle == INTERNET_INVALID_HANDLE) {
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
   } else if (StringSubstr(url, 0, 4) == INTERNET_PROTOCOL_HTTP) {
      port = INTERNET_DEFAULT_HTTP_PORT;
   } else {
      #ifdef HTTP_LIBRARY_LOGGING
         Print("Invalid protocol present on URL ", url);
      #endif
      SetUserError(INTERNET_PROTOCOL_INVALID_ERROR);
      return;
   }
   
   // Attempt to create an intenrnet connection to the URL at the desired port; if this 
   // fails then return an error
   m_session_handle = InternetConnectW(m_open_handle, url, port, NULL, NULL, 
      INTERNET_SERVICE_DEFAULT, INTERNET_FLAG_NO_UI, 1);
   if (session == INTERNET_INVALID_HANDLE) {
      #ifdef HTTP_LIBRARY_LOGGING
         int errCode = GetLastError();
         PrintFormat("Failed to connect to %s:%d, error: %d", url, port, errCode);
      #endif
      SetUserError(INTERNET_CONNECT_FAILED_ERROR);
      return;
   }
   
   // Now, setup the accept headers and ensure that the last value is a NULL
   string accepts[];
   ArrayCopy(accepts, accept);
   int length = ArraySize(accepts);
   if (length > 0 && accepts[length - 1] != NULL) {
      ArrayResize(accepts, length + 1);
      accepts[length] = NULL;
   }
   
   // Finally, open the HTTP request with the session variable, verb and URL; if this fails
   // then log and return an error
   m_request_handle = HttpOpenRequestW(m_session_handle, verb, url, NULL, referrer, 
      accepts, INTERNET_FLAG_NO_UI, 1);
   if (request == INTERNET_INVALID_HANDLE) {
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

// Destroys this instance of the HTTP request, releasing all the resources controlled by this request
~HttpRequest::HttpRequest() {
   
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

// Adds a header to the HTTP request. If this fails then a non-zero error code will be returned.
// Otherwise, this function will return zero.
//    name:       The name of the header
//    value:      The value to set to the header
//    coalesce:   True to allow multiple header values to be associated with the same header name.
//                False, to overwrite the existing value if the header name already exists
int HttpRequest::AddHeader(const string name, const string value, const bool coalesce) const {
   
   // First, check that the request is read. If it isn't then return an erorr
   if (!m_ready) {
      return INTERNET_REQUEST_NOT_READY;
   }
   
   // Next, create the header from the name and value
   string header = name + ":" + value;

   // Now, get the code. If we want to coalesce the header then set the coalesce flag. Otherwise,
   // set the replace flag. We'll set the add flag as well
   int code = HTTP_ADDREQ_FLAG_ADD;
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

// Sends the HTTP request to the server, with the request body provided. I:f this function fails then
// a non-zero error will be returned. Otherwise, this function will return zero.
//    body:       The request body to send with the request
//    response:   The HTTP resposne that will contain the status code and response body
int HttpRequest::SendRequest(const string body, HttpResponse &response) {
   
   // First, check that the request is ready to send. If it's not then return an error
   if (!m_ready) {
      return INTERNET_REQUEST_NOT_READY;
   }

   // Next, attempt to send the request to the server; if this fails then return an error
   if (!HttpSendRequestW(m_request_handle, NULL, 0, body, ArraySize(body))) {
      #ifdef HTTP_LIBRARY_LOGGING
         int errCode = GetLastError();
         PrintFormat("Failed to send HTTP request, error: %d", errCode);
      #endif
      return INTERNET_SEND_FAILED_ERROR;
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
   if (!HttpQueryInfo(m_request_handle, HTTP_QUERY_STATUS_CODE | HTTP_QUERY_FLAG_NUMBER, 
      response.StatusCode, sizeof(response.StatusCode), NULL)) {
      #ifdef HTTP_LIBRARY_LOGGING
         int errCode = GetLastError();
         PrintFormat("Failed to get status code from HTTP response, error: %d", errCode);
      #endif
      return INTERNET_READ_RESP_FAILED_ERROR;
   }
   
   return 0;
}