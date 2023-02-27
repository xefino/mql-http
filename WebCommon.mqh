#property copyright "Xefino"
#property version   "1.05"
#property strict

// Internet-related error codes that will be returned
#define ERROR_NO_MORE_FILES                  18
#define INTERNET_OPEN_FAILED_ERROR           5000
#define INTERNET_PROTOCOL_INVALID_ERROR      5001
#define INTERNET_CONNECT_FAILED_ERROR        5002
#define INTERNET_OPEN_REQUEST_FAILED_ERROR   5003
#define INTERNET_ADD_HEADER_FAILED_ERROR     5004
#define INTERNET_SEND_FAILED_ERROR           5005
#define INTERNET_RECEIVE_FAILED_ERROR        5006
#define INTERNET_READ_RESP_FAILED_ERROR      5007
#define INTERNET_REQUEST_NOT_READY           5008

// Constant values for internet-related code
#define INTERNET_INVALID_HANDLE     0
#define INTERNET_BUFFER_LENGTH      1024

// Constant flags for opening a new internet connection
#define INTERNET_OPEN_TYPE_PRECONFIG                     0
#define INTERNET_OPEN_TYPE_DIRECT                        1
#define INTERNET_OPEN_TYPE_PROXY_BYPASS                  2
#define INTERNET_OPEN_TYPE_PROXY                         3
#define INTERNET_OPEN_TYPE_PRECONFIG_WITH_NO_AUTOPROXY   4

// Constant flags used when creating a session or registering a request
#define INTERNET_FLAG_NO_UI                     0x00000200
#define INTERNET_FLAG_RESYNCHRONIZE             0x00000800
#define INTERNET_FLAG_MUST_CACHE_REQUEST        0x00001000
#define INTERNET_FLAG_IGNORE_REDIRECT_TO_HTTPS  0x00004000
#define INTERNET_FLAG_IGNORE_REDIRECT_TO_HTTP   0x00008000
#define INTERNET_FLAG_CACHE_IF_NET_FAIL         0x00010000
#define INTERNET_FLAG_NO_COOKIES                0x00080000
#define INTERNET_FLAG_NO_AUTO_REDIRECT          0x00200000
#define INTERNET_FLAG_KEEP_CONNECTION           0x00400000
#define INTERNET_FLAG_SECURE                    0x00800000
#define INTERNET_FLAG_OFFLINE                   0x01000000
#define INTERNET_FLAG_FROM_CACHE                0x01000000
#define INTERNET_FLAG_NO_CACHE_WRITE            0x04000000
#define INTERNET_FLAG_PASSIVE                   0x08000000
#define INTERNET_FLAG_ASYNC                     0x10000000
#define INTERNET_FLAG_RELOAD                    0x80000000

// Common port numbers to use when making web requests
#define INTERNET_DEFAULT_FTP_PORT      21
#define INTERNET_DEFAULT_GOPHER_PORT   70
#define INTERNET_DEFAULT_HTTP_PORT     80
#define INTERNET_DEFAULT_HTTPS_PORT    443
#define INTERNET_DEFAULT_SOCKS_PORT    1080

// Common flags to use when declaring the web request service type
#define INTERNET_SERVICE_DEFAULT 0
#define INTERNET_SERVICE_FTP     1
#define INTERNET_SERVICE_GOPHER  2
#define INTERNET_SERVICE_HTTP    3
#define INTERNET_SERVICE_FILE    4
#define INTERNET_SERVICE_HTTPS   6
#define INTERNET_SERVICE_SFTP    7

// Common flags to use when adding a new header to the HTTP request
#define HTTP_ADDREQ_FLAG_COALESCE_WITH_SEMICOLON   0x01000000
#define HTTP_ADDREQ_FLAG_ADD_IF_NEW                0x10000000
#define HTTP_ADDREQ_FLAG_ADD                       0x20000000
#define HTTP_ADDREQ_FLAG_COALESCE                  0x40000000
#define HTTP_ADDREQ_FLAG_COALESCE_WITH_COMMA       0x40000000
#define HTTP_ADDREQ_FLAG_REPLACE                   0x80000000

// Common HTTP header query flags
#define HTTP_QUERY_MIME_VERSION              0
#define HTTP_QUERY_CONTENT_TYPE              1
#define HTTP_QUERY_CONTENT_TRANSFER_ENCODING 2
#define HTTP_QUERY_CONTENT_ID                3
#define HTTP_QUERY_CONTENT_DESCRIPTION       4
#define HTTP_QUERY_CONTENT_LENGTH            5
#define HTTP_QUERY_CONTENT_LANGUAGE          6
#define HTTP_QUERY_ALLOW                     7
#define HTTP_QUERY_PUBLIC                    8
#define HTTP_QUERY_DATE                      9
#define HTTP_QUERY_EXPIRES                   10
#define HTTP_QUERY_LAST_MODIFIED             11
#define HTTP_QUERY_MESSAGE_ID                12
#define HTTP_QUERY_URI                       13
#define HTTP_QUERY_DERIVED_FROM              14
#define HTTP_QUERY_COST                      15
#define HTTP_QUERY_LINK                      16
#define HTTP_QUERY_PRAGMA                    17
#define HTTP_QUERY_VERSION                   18
#define HTTP_QUERY_STATUS_CODE               19
#define HTTP_QUERY_STATUS_TEXT               20
#define HTTP_QUERY_RAW_HEADERS               21
#define HTTP_QUERY_RAW_HEADERS_CRLF          22
#define HTTP_QUERY_CONNECTION                23
#define HTTP_QUERY_ACCEPT                    24
#define HTTP_QUERY_ACCEPT_CHARSET            25
#define HTTP_QUERY_ACCEPT_ENCODING           26
#define HTTP_QUERY_ACCEPT_LANGUAGE           27
#define HTTP_QUERY_AUTHORIZATION             28
#define HTTP_QUERY_CONTENT_ENCODING          29
#define HTTP_QUERY_FORWARDED                 30
#define HTTP_QUERY_FROM                      31
#define HTTP_QUERY_IF_MODIFIED_SINCE         32
#define HTTP_QUERY_LOCATION                  33
#define HTTP_QUERY_ORIG_URI                  34
#define HTTP_QUERY_REFERER                   35
#define HTTP_QUERY_RETRY_AFTER               36
#define HTTP_QUERY_SERVER                    37
#define HTTP_QUERY_TITLE                     38
#define HTTP_QUERY_USER_AGENT                39
#define HTTP_QUERY_WWW_AUTHENTICATE          40
#define HTTP_QUERY_PROXY_AUTHENTICATE        41
#define HTTP_QUERY_ACCEPT_RANGES             42
#define HTTP_QUERY_SET_COOKIE                43
#define HTTP_QUERY_COOKIE                    44
#define HTTP_QUERY_REQUEST_METHOD            45
#define HTTP_QUERY_REFRESH                   46
#define HTTP_QUERY_CONTENT_DISPOSITION       47
#define HTTP_QUERY_AGE                       48
#define HTTP_QUERY_CACHE_CONTROL             49
#define HTTP_QUERY_CONTENT_BASE              50
#define HTTP_QUERY_CONTENT_LOCATION          51
#define HTTP_QUERY_CONTENT_MD5               52
#define HTTP_QUERY_CONTENT_RANGE             53
#define HTTP_QUERY_ETAG                      54
#define HTTP_QUERY_HOST                      55
#define HTTP_QUERY_IF_MATCH                  56
#define HTTP_QUERY_IF_NONE_MATCH             57
#define HTTP_QUERY_IF_RANGE                  58
#define HTTP_QUERY_IF_UNMODIFIED_SINCE       59
#define HTTP_QUERY_MAX_FORWARDS              60
#define HTTP_QUERY_PROXY_AUTHORIZATION       61
#define HTTP_QUERY_RANGE                     62
#define HTTP_QUERY_TRANSFER_ENCODING         63
#define HTTP_QUERY_UPGRADE                   64
#define HTTP_QUERY_VARY                      65
#define HTTP_QUERY_VIA                       66
#define HTTP_QUERY_WARNING                   67
#define HTTP_QUERY_EXPECT                    68
#define HTTP_QUERY_PROXY_CONNECTION          69
#define HTTP_QUERY_UNLESS_MODIFIED_SINCE     70
#define HTTP_QUERY_ECHO_REQUEST              71
#define HTTP_QUERY_ECHO_REPLY                72
#define HTTP_QUERY_ECHO_HEADERS              73
#define HTTP_QUERY_ECHO_HEADERS_CRLF         74
#define HTTP_QUERY_MAX                       78
#define HTTP_QUERY_X_CONTENT_TYPE_OPTIONS    79
#define HTTP_QUERY_P3P                       80
#define HTTP_QUERY_X_P2P_PEERDIST            81
#define HTTP_QUERY_TRANSLATE                 82
#define HTTP_QUERY_X_UA_COMPATIBLE           83
#define HTTP_QUERY_DEFAULT_STYLE             84
#define HTTP_QUERY_X_FRAME_OPTIONS           85
#define HTTP_QUERY_X_XSS_PROTECTION          86
#define HTTP_QUERY_CUSTOM                    65535
#define HTTP_QUERY_FLAG_COALESCE             0x10000000
#define HTTP_QUERY_FLAG_NUMBER               0x20000000
#define HTTP_QUERY_FLAG_SYSTEMTIME           0x40000000
#define HTTP_QUERY_FLAG_REQUEST_HEADERS      0x80000000

// DLL imports
#import "Wininet.dll"

   // Attempts to make a connection to the Internet.
   int InternetAttemptConnect(uint dwReserved);

   // Initializes an application's use of the WinINet functions.
   int InternetOpenW(string, int, string, string, int);
   
   // Opens an File Transfer Protocol (FTP) or HTTP session for a given site.
   int InternetConnectW(int, string, int, string, string, int, int, int); 
   
   // Creates an HTTP request handle.
   int HttpOpenRequestW(int, string, string, string, string, string& AcceptTypes[], int, int);
   
   // Adds one or more HTTP request headers to the HTTP request handle.
   bool HttpAddRequestHeadersW(int, string, int, uint);
   
   // Sends the specified request to the HTTP server
   bool HttpSendRequestW(int, string, int, char &result[], int);
   
   // Reads data from a handle opened by the InternetOpenUrl, FtpOpenFile, or HttpOpenRequest function.
   bool InternetReadFile(int, char &result[], int, int&);
   
   // Retrieves header information associated with an HTTP request.
   bool HttpQueryInfoW(int, int, int&, int&, int&);
   
   // Closes a single Internet handle.
   bool InternetCloseHandle(int);
#import

// Constant string values for internet protocols
const string INTERNET_PROTOCOL_HTTP = "http";
const string INTERNET_PROTOCOL_HTTPS = "https";