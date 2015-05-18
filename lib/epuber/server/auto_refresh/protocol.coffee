
# most of this code is based on https://github.com/livereload/livereload-js/blob/master/src/protocol.coffee
#

class @ProtocolError
    constructor: (reason, data) ->
        @message = "LiveReload protocol error (#{reason}) after receiving data: \"#{data}\"."

class @ProtocolParser
    constructor: (@handler) ->
        @reset()

    reset: ->
        @send_hello = false

    process: (data) ->
        try
            if not @send_hello
                message = @_parseMessage(data, ['hello'])
                @send_hello = true
                @handler.connected(message)
            else
                message = @_parseMessage(data, ['heartbeat', 'styles', 'reload', 'compile_start', 'compile_end'])
                @handler.message(message)
        catch e
            if e instanceof ProtocolError
                @handler.error e
            else
                throw e

    _parseMessage: (data, validNames) ->
        try
            message = JSON.parse(data)
        catch e
            throw new ProtocolError('unparsable JSON', data)
        unless message.name
            throw new ProtocolError('missing "name" key', data)
        unless message.name in validNames
            throw new ProtocolError("invalid command '#{message.name}', only valid commands are: #{validNames.join(', ')})", data)

        return message
