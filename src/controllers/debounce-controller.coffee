_ = require 'lodash'
util = require 'util'

class DebounceController
  constructor: ({@debounceService}) ->

  debounce: (request, response) =>
    {method, body} = request
    headers = {}
    {id, wait} = request.params
    {url} = request.query
    contentType = ''

    _.forEach _.filter(request.rawHeaders, (item, index) => index%2 == 0), (key) =>
      lowKey = key.toLowerCase()
      headers[key] = request.headers[lowKey] unless lowKey == 'host'
      contentType = headers[key] if lowKey == 'content-type'

    console.log {id, wait, url, contentType, method, headers, body}

    if contentType.toLowerCase() == 'application/json'
      console.log 'is of type json'

    # console.log util.inspect(request)
    response.sendStatus(200)
    # @debounceService.doDebounce {id, method, url}, (error) =>
    #   return response.status(error.code || 500).send(error: error.message) if error?
    #   response.sendStatus(200)

module.exports = DebounceController
