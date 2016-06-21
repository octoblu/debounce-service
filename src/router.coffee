DebounceController = require './controllers/debounce-controller'

class Router
  constructor: ({@debounceService}) ->
  route: (app) =>
    debounceController = new DebounceController {@debounceService}

    app.get '/hello', debounceController.hello
    # e.g. app.put '/resource/:id', someController.update

module.exports = Router
