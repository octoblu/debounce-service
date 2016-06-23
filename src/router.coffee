class Router
  constructor: ({@debounceController}) ->
  route: (app) =>
    app.all '/debounce/:id', @debounceController.debounce

module.exports = Router
