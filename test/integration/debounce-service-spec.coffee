_       = require 'lodash'
http    = require 'http'
request = require 'request'
shmock  = require 'shmock'
debug   = require('debug')('debounce-service:test')
Server  = require '../../src/server'

REPEAT_DEBOUNCE_TEST=3

describe 'Debounce', ->
  beforeEach (done) ->
    minPort = 49152
    maxPort = 65535
    @port = Math.round(Math.random() * (maxPort - minPort) + minPort)
    @portHttp1 = Math.round(Math.random() * (maxPort - minPort) + minPort)
    @portHttp2 = Math.round(Math.random() * (maxPort - minPort) + minPort)

    @server = new Server {@port, waitDefault:0}
    @server.run done

  afterEach (done) ->
    @server.stop done

  describe 'On GET /debouce', ->
    describe 'when given a request without an id', ->
      beforeEach (done) ->
        options =
          url: "http://localhost:#{@port}/debounce/"

        request.get options, (error, @response, @body) =>
          done error

      it 'should return a 404', ->
        expect(@response.statusCode).to.equal 404

    describe 'when given a request without a url', ->
      beforeEach (done) ->
        options =
          url: "http://localhost:#{@port}/debounce/lolkey"

        request.get options, (error, @response, @body) =>
          done error

      it 'should return a 417 with correct body', ->
        expect(@response.statusCode).to.equal 417
        expect(JSON.parse @body).to.deep.equal { error: 'Request url not defined' }

  describe 'when given a _requestOptions with url in query string', ->
    beforeEach (done) ->
      @http1 = shmock @portHttp1
      @getFoo = @http1.get("/foo").reply(200,'ok');

      options =
        url: "http://localhost:#{@port}/debounce/lolol"
        qs:
          _requestOptions: JSON.stringify
            url: "http://localhost:#{@portHttp1}/foo"

      request.get options, (error, @response, @body) =>
        done()

    beforeEach (done) ->
      @getFoo.wait done

    it 'should get request the provided url', ->
      expect(@response.statusCode).to.equal 200
      expect(@getFoo.isDone).to.equal true

  describe 'when given a _requestOptions and _responseOptions with url in query string', ->
    beforeEach (done) ->

      @http1 = shmock @portHttp1
      @getBar = @http1.get('/bar').reply(418, {teapot: true}, {hello: 'world'});

      @http2 = shmock @portHttp2
      @postBaz = @http2.post('/baz')
        .send({teapot:true})
        .set('hello', 'world')
        .set('response-status-code', '418')
        .reply(200,'ok');

      options =
        url: "http://localhost:#{@port}/debounce/wut"
        qs:
          _requestOptions: JSON.stringify
            url: "http://localhost:#{@portHttp1}/bar"
          _responseOptions: JSON.stringify
            url: "http://localhost:#{@portHttp2}/baz"

      request.get options, (error, @response, @body) =>
        done()

    beforeEach (done) ->
      @getBar.wait done

    beforeEach (done) ->
      @postBaz.wait done

    it 'should get request the provided url, then post response', ->
      # console.log {@postBaz}
      expect(@response.statusCode).to.equal 200
      expect(@postBaz.isDone).to.equal true

  describe 'when given a _requestOptions and _responseOptions with url in query string', ->
    beforeEach (done) ->

      @http1 = shmock @portHttp1
      @getBar = @http1.get('/bar').reply(418, {teapot: true}, {hello: 'world'});

      @http2 = shmock @portHttp2
      @postBaz = @http2.post('/baz')
        .send({teapot:true})
        .set('hello', 'world')
        .set('response-status-code', '418')
        .reply(200,'ok');

      options =
        url: "http://localhost:#{@port}/debounce/wut"
        qs:
          _requestOptions: JSON.stringify
            url: "http://localhost:#{@portHttp1}/bar"
          _responseOptions: JSON.stringify
            url: "http://localhost:#{@portHttp2}/baz"

      request.get options, (error, @response, @body) =>
        done()

    beforeEach (done) ->
      @getBar.wait done

    beforeEach (done) ->
      @postBaz.wait done

    it 'should get request the provided url, then post response', ->
      # console.log {@postBaz}
      expect(@response.statusCode).to.equal 200
      expect(@postBaz.isDone).to.equal true

  describe 'when given a different method and additional response query strings', ->
    beforeEach (done) ->
      queryString =

      @http1 = shmock @portHttp1
      @deleteWobble = @http1.delete('/wobble')
        .query({ diddy: 'wishingwell', dribble: 'spin' })
        .reply(420, {enhance: 'calm'}, {twit: 'twut'});

      @http2 = shmock @portHttp2
      @putWubble = @http2.put('/wubble')
        .query({ weeble: 'rolypoly', float: 'smash' })
        .send({enhance: 'calm'})
        .set('twit', 'twut')
        .set('dont', 'fall over')
        .set('response-status-code', '420')
        .reply(200,'ok');

      options =
        url: "http://localhost:#{@port}/debounce/wibble"
        qs:
          _requestOptions: JSON.stringify
            url: "http://localhost:#{@portHttp1}/wobble?diddy=wishingwell"
          _responseOptions: JSON.stringify
            url: "http://localhost:#{@portHttp2}/wubble?weeble=rolypoly"
            method: 'PUT'
            qs:
              float: 'smash'
            headers:
              dont: 'fall over'
          dribble: 'spin'

      request.delete options, (error, @response, @body) =>
        done()

    beforeEach (done) ->
      @deleteWobble.wait done

    beforeEach (done) ->
      @putWubble.wait done

    it 'should get request the provided url, then post response', ->
      # console.log {@putWubble}
      expect(@response.statusCode).to.equal 200
      expect(@putWubble.isDone).to.equal true

  describe 'when given a debounce wait value and many requests', ->
    beforeEach (done) ->
      queryString =

      @http1 = shmock @portHttp1
      @deleteWobble = @http1.patch('/zobble')
        .query({ ziddy: 'star', zibble: 'spin' })
        .send({request: REPEAT_DEBOUNCE_TEST})
        .reply(421, {too: 'late'}, {zit: 'zut'});

      @http2 = shmock @portHttp2
      @putWubble = @http2.put('/zubble')
        .query({ zeeble: 'lolly', boat: 'dash' })
        .send({too: 'late'})
        .set('zit', 'zut')
        .set('wont', 'fall down')
        .set('response-status-code', '421')
        .reply(200,'ok');

      options =
        url: "http://localhost:#{@port}/debounce/zibble"
        json: true
        body:
          request: 0
        qs:
          _debounce: JSON.stringify
            wait: 1000
          _requestOptions: JSON.stringify
            url: "http://localhost:#{@portHttp1}/zobble?ziddy=star"
          _responseOptions: JSON.stringify
            url: "http://localhost:#{@portHttp2}/zubble?zeeble=lolly"
            method: 'PUT'
            qs:
              boat: 'dash'
            headers:
              wont: 'fall down'
          zibble: 'spin'

      doRequest = () =>
        options.body.request++
        options = _.cloneDeep(options)
        debug 'sending request', options.body.request
        request.patch options
        return done() if options.body.request==REPEAT_DEBOUNCE_TEST
        setTimeout doRequest, 10

      doRequest()

    beforeEach (done) ->
      @deleteWobble.wait done

    beforeEach (done) ->
      @putWubble.wait done

    it 'should send the last request', ->
      expect(@putWubble.isDone).to.equal true

  describe 'when given a noUpdate key in _service and many requests', ->
    beforeEach (done) ->
      queryString =

      @http1 = shmock @portHttp1
      @deleteWobble = @http1.patch('/zobble')
        .query({ ziddy: 'star', zibble: 'spin' })
        .send({request: 1})
        .reply(421, {too: 'late'}, {zit: 'zut'});

      @http2 = shmock @portHttp2
      @putWubble = @http2.put('/zubble')
        .query({ zeeble: 'lolly', boat: 'dash' })
        .send({too: 'late'})
        .set('zit', 'zut')
        .set('wont', 'fall down')
        .set('response-status-code', '421')
        .reply(200,'ok');

      options =
        url: "http://localhost:#{@port}/debounce/zibble"
        json: true
        body:
          request: 0
        qs:
          _service: JSON.stringify
            noUpdate: true
          _debounce: JSON.stringify
            wait: 1000
          _requestOptions: JSON.stringify
            url: "http://localhost:#{@portHttp1}/zobble?ziddy=star"
          _responseOptions: JSON.stringify
            url: "http://localhost:#{@portHttp2}/zubble?zeeble=lolly"
            method: 'PUT'
            qs:
              boat: 'dash'
            headers:
              wont: 'fall down'
          zibble: 'spin'

      doRequest = () =>
        options.body.request++
        options = _.cloneDeep(options)
        debug 'sending request', options.body.request
        request.patch options
        return done() if options.body.request==REPEAT_DEBOUNCE_TEST
        setTimeout doRequest, 10

      doRequest()

    beforeEach (done) ->
      @deleteWobble.wait done

    beforeEach (done) ->
      @putWubble.wait done

    it 'should send the first request', ->
      expect(@putWubble.isDone).to.equal true

  describe 'when given a leading debounce option and many requests', ->
    beforeEach (done) ->
      queryString =

      @http1 = shmock @portHttp1
      @deleteWobble = @http1.patch('/zobble')
        .query({ ziddy: 'star', zibble: 'spin' })
        .send({request: 1})
        .reply(421, {too: 'late'}, {zit: 'zut'});

      @http2 = shmock @portHttp2
      @putWubble = @http2.put('/zubble')
        .query({ zeeble: 'lolly', boat: 'dash' })
        .send({too: 'late'})
        .set('zit', 'zut')
        .set('wont', 'fall down')
        .set('response-status-code', '421')
        .reply(200,'ok');

      options =
        url: "http://localhost:#{@port}/debounce/zibble"
        json: true
        body:
          request: 0
        qs:
          _debounce: JSON.stringify
            wait: 1000
            options:
              leading: true
              trailing: false
          _requestOptions: JSON.stringify
            url: "http://localhost:#{@portHttp1}/zobble?ziddy=star"
          _responseOptions: JSON.stringify
            url: "http://localhost:#{@portHttp2}/zubble?zeeble=lolly"
            method: 'PUT'
            qs:
              boat: 'dash'
            headers:
              wont: 'fall down'
          zibble: 'spin'

      doRequest = () =>
        options.body.request++
        options = _.cloneDeep(options)
        debug 'sending request', options.body.request
        request.patch options
        return setTimeout done, 500 if options.body.request==REPEAT_DEBOUNCE_TEST
        setTimeout doRequest, 10

      doRequest()

    beforeEach (done) ->
      return done() if @putWubble.isDone
      @putWubble.wait done

    it 'should send the first request', ->
      expect(@putWubble.isDone).to.equal true
