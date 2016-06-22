DebounceController = require './controllers/debounce-controller'

class Router
  constructor: ({@debounceService}) ->
  route: (app) =>
    debounceController = new DebounceController {@debounceService}

    app.all '/debounce/:id', debounceController.debounce
    app.all '/debounce/:id/wait/:wait', debounceController.debounce

module.exports = Router
