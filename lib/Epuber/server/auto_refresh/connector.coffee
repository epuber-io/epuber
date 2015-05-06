
# most of this code is based on https://github.com/livereload/livereload-js/blob/master/src/connector.coffee
#
class @Connector
    MIN_DELAY = 1000
    MAX_DELAY = 60 * 1000
    HANDSHAKE_TIMEOUT = 5000

    constructor: (url, @WebSocket, @console, @Timer, @_handler) ->
        uri = URI(url)
        newScheme =
            switch uri.protocol()
                when 'http'
                    'ws'
                when 'https'
                    'wss'
        uri.protocol(newScheme)
        @_uri = uri.toString()

        @_nextDelay = MIN_DELAY
        @_connectionDesired = no

        @protocolParser = new ProtocolParser
            connected: (hello_message) =>
                @_handshakeTimeout.stop()
                @_nextDelay = MIN_DELAY
                @_disconnectionReason = 'broken'
                @_callHandler('connected', hello_message)

            error: (e) =>
                @_callHandler('error', e)
                @_closeOnError()

            message: (message) =>
                if message.name == 'heartbeat'
                    # TODO: reset timeout timer
                else
                    @_callHandler('message', message)

        @_handshakeTimeout = new Timer =>
            return unless @_isSocketConnected()
            @console.error('Connector: Handshake timed out')
            @_disconnectionReason = 'handshake-timeout'
            @socket.close()

        @_reconnectTimer = new Timer =>
            return unless @_connectionDesired  # shouldn't hit this, but just in case
            @connect()

        @connect()


    _isSocketConnected: ->
        @socket and @socket.readyState is @WebSocket.OPEN

    connect: ->
        @_connectionDesired = yes
        return if @_isSocketConnected()

        @protocolParser.reset()

        # prepare for a new connection
        @_reconnectTimer.stop()
        @_disconnectionReason = 'cannot-connect'

        @_callHandler('connecting')

        @socket = new @WebSocket(@_uri)
        @socket.onopen    = (e) => @_onopen(e)
        @socket.onclose   = (e) => @_onclose(e)
        @socket.onmessage = (e) => @_onmessage(e)
        @socket.onerror   = (e) => @_onerror(e)

    disconnect: (reason = 'manual')->
        @_connectionDesired = no
        @_reconnectTimer.stop()   # in case it was running
        return unless @_isSocketConnected()
        @_disconnectionReason = reason
        @socket.close()


    _scheduleReconnection: ->
        return unless @_connectionDesired  # don't reconnect after manual disconnection
        unless @_reconnectTimer.running
            @_reconnectTimer.start(@_nextDelay)
            @_nextDelay = Math.min(MAX_DELAY, @_nextDelay * 2)

    _callHandler: (message, arg...) ->
        func = @_handler[message]
        if func?
            func(arg...)
        else
            @console.error("Connector: error: handler doesn't know #{message}")

    sendMessage: (name, data) ->
        message =
            name: name

        message.data = data if data?

        @socket.send(JSON.stringify(message))

    _closeOnError: ->
        @_handshakeTimeout.stop()
        @_disconnectionReason = 'error'
        @socket.close()

    _onopen: (e) ->
        @_callHandler('socketConnected')
        @_disconnectionReason = 'handshake-failed'

        # start handshake
        @sendMessage('hello')
        @_handshakeTimeout.start(HANDSHAKE_TIMEOUT)

    _onclose: (e) ->
        @_callHandler('disconnected', @_disconnectionReason, @_nextDelay)
        @_scheduleReconnection()

    _onerror: (e) ->
        @_callHandler('error', e)
        @console.error("Connector: #{e}")

    _onmessage: (e) ->
        @protocolParser.process(e.data)
