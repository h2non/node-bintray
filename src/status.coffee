# Reference:
# http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
# http://www.w3.org/Protocols/rfc2616/rfc2616-sec6.html#sec6.1.1

module.exports =
  # Informational 1xx
  # Request received, continuing process
  100: 'Continue'
  101: 'Switching Protocols'

  # Successful 2xx
  # The action was successfully received, understood, and accepted
  200: 'OK'
  201: 'Created'
  202: 'Accepted'
  203: 'Non-Authoritative Information'
  204: 'No Content'
  205: 'Reset Content'
  206: 'Partial Content'

  # Redirection 3xx
  # Further action must be taken in order to complete the request
  300: 'Multiple Choices'
  301: 'Moved Permanently'
  302: 'Found'
  303: 'See Other'
  304: 'Not Modified'
  305: 'Use Proxy'
  307: 'Temporary Redirect'

  # Client Error 4xx
  # The request contains bad syntax or cannot be fulfilled
  400: 'Bad Request'
  401: 'Unauthorized'
  402: 'Payment Required'
  403: 'Forbidden'
  404: 'Not Found'
  405: 'Method Not Allowed'
  406: 'Not Acceptable'
  407: 'Proxy Authentication Required'
  408: 'Request Time-out'
  409: 'Conflict'
  410: 'Gone'
  411: 'Length Required'
  412: 'Precondition Failed'
  413: 'Request Entity Too Large'
  414: 'Request-URI Too Large'
  415: 'Unsupported Media Type'
  416: 'Requested range not satisfiable'
  417: 'Expectation Failed'

  # Server Error 5xx
  # The server failed to fulfill an apparently valid request
  500: 'Internal Server Error'
  501: 'Not Implemented'
  502: 'Bad Gateway'
  503: 'Service Unavailable'
  504: 'Gateway Time-out'
  505: 'HTTP Version not supported'