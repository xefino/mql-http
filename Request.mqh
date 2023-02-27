#property copyright "Xefino"
#property version   "1.04"
#property strict

#include "Requester.mqh"
#include "Response.mqh"

// HttpRequest
// Contains information sent to an HTTP request. This is meant to be the main control
// structure for sending HTTP requests and receiving HTTP responses
class HttpRequest {
private:
   string   m_verb;              // The HTTP method name (GET, POST, PUT, etc.)
   string   m_url;               // The URL to send the HTTP request
   string   m_body;              // The body of the HTTP request
   string   m_referrer;          // The referrer of the request
   int      m_num_headers;       // The number of headers to send with the request
   string   m_header_names[];    // The names of the headers to send with the request
   string   m_header_values[];   // The values of the headers to send with the request
   bool     m_header_coalesce[]; // The coalesce flags of all the headers to send
   
public:
   
   // Creates a new instance of the HTTP request object
   //    verb:       The HTTP method type we'll be using for this request
   //    url:        The URL we'll be requesting
   //    body:       The body of the request; this can be empty for GET requests
   //    referrer:   The referrer for the HTTP request
   HttpRequest(const string verb, const string url, const string body = NULL, 
      const string referrer = NULL);

   // AddHeader records a header name and value to the HTTP request. IF the coalesce
   // flag is true, then header values with the same name will be coalesced into a single
   // header record. Otherwise, successive header values with the same name will overwrite
   // previous values.
   //    name:       The name of the header
   //    value:      The value of the header
   //    coalesce:   Whether the header should be coalesced or not
   void AddHeader(const string name, const string value, const bool coalesce = false);
   
   // Send compiles the web request and sends it to the remote server. This function will
   // return zero if the function succeeded or will return a non-zero value indicating the
   // error code, otherwise.
   //    response:   The object that will contain the data from the HTTP response
   int Send(HttpResponse &response) const;
};

// Creates a new instance of the HTTP request object
//    verb:       The HTTP method type we'll be using for this request
//    url:        The URL we'll be requesting
//    body:       The body of the request; this can be empty for GET requests
//    referrer:   The referrer for the HTTP request
HttpRequest::HttpRequest(const string verb, const string url, const string body = NULL, 
   const string referrer = NULL) {
   m_verb = verb;
   m_url = url;
   m_body = body;
   m_referrer = referrer;
   m_num_headers = 0;   
}

// AddHeader records a header name and value to the HTTP request. IF the coalesce
// flag is true, then header values with the same name will be coalesced into a single
// header record. Otherwise, successive header values with the same name will overwrite
// previous values.
//    name:       The name of the header
//    value:      The value of the header
//    coalesce:   Whether the header should be coalesced or not
void HttpRequest::AddHeader(const string name, const string value, const bool coalesce = false) {
   
   // First, calculate the new size of the headers array and resize our list of header names,
   // header values and header coalesce flags
   int newSize = m_num_headers + 1;
   ArrayResize(m_header_names, newSize);
   ArrayResize(m_header_values, newSize);
   ArrayResize(m_header_coalesce, newSize);
   
   // Next, set the last index of the headers array with our name, value and coalesce flag
   m_header_names[m_num_headers] = name;
   m_header_values[m_num_headers] = value;
   m_header_coalesce[m_num_headers] = coalesce;
   
   // Finally, update the header length with the new size
   m_num_headers = newSize;
}

// Send compiles the web request and sends it to the remote server. This function will
// return zero if the function succeeded or will return a non-zero value indicating the
// error code, otherwise.
//    response:   The object that will contain the data from the HTTP response
int HttpRequest::Send(HttpResponse &response) const {

   // First, check the protocol associated with the request. Also, if we have an HTTPS
   // request then set the secure flag to true. Otherwise, if the protocol isn't one we
   // recognize then return an error
   int port, offset;
   bool secure = false;
   if (StringSubstr(m_url, 0, 5) == INTERNET_PROTOCOL_HTTPS) {
      port = INTERNET_DEFAULT_HTTPS_PORT;
      offset = 8;
      secure = true;
   } else if (StringSubstr(m_url, 0, 4) == INTERNET_PROTOCOL_HTTP) {
      port = INTERNET_DEFAULT_HTTP_PORT;
      offset = 6;
   } else {
      #ifdef HTTP_LIBRARY_LOGGING
         Print("Invalid protocol present on URL ", m_url);
      #endif
      return INTERNET_PROTOCOL_INVALID_ERROR;
   }
   
   // Use the offset we calculated to find the index of the resource we're requesting. If we don't
   // have a resource then we'll use a slash; otherwise, we'll get everything from the slash onward
   string host, resource;
   int slashIndex = StringFind(m_url, "/", offset);
   if (slashIndex == -1) {
      host = m_url;
      resource = "/";
   } else {
      host = StringSubstr(m_url, 0, slashIndex);
      resource = StringSubstr(m_url, slashIndex);
   }
   
   // Log the request details now
   #ifdef HTTP_LIBRARY_LOGGING
      PrintFormat("Sending HTTP request to host %s, resource %s at port %d", host, resource, port);
   #endif

   // Next, create our HTTP reqeuster from the verb, URL and referrer; if this fails then return an error
   HttpRequester *req = new HttpRequester(m_verb, host, resource, port, secure, m_referrer);
   int errCode = GetLastError();
   if (errCode != 0 && errCode != ERR_UNKNOWN_COMMAND) {
      return errCode;
   }
   
   // Now, iterate over our headers and attempt to add each to the requester; if this fails then return an error
   for (int i = 0; i < m_num_headers; i++) {
      errCode = req.AddHeader(m_header_names[i], m_header_values[i], m_header_coalesce[i]);
      if (errCode != 0) {
         return errCode;
      }
   }
   
   // Finally, attempt to send the request and record data in the response
   return req.SendRequest(m_body, response);
}
