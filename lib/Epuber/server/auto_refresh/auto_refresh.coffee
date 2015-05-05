
# most of this code is based on https://github.com/livereload/livereload-js/blob/master/src/livereload.coffee
#

class @AutoRefresh
    MESSAGE_MAP =
        styles: ReloaderContext.ReloadType.style
        reload: ReloaderContext.ReloadType.reload
        compile_start: ReloaderContext.ReloadType.compilation_begin
        compile_end: ReloaderContext.ReloadType.compilation_end

    constructor: (@window, @console) ->
        unless @WebSocket = @window.WebSocket || @window.MozWebSocket
            @console.error("AutoRefresh disabled because the browser does not seem to support web sockets")
            return

        @reloader = new ReloaderContext(@window, @console)

        @connector = new Connector window.location, @WebSocket, @console, Timer,
            connecting: =>
            socketConnected: =>
            connected: =>
                @console.info("AutoRefresh: connection to server established")

            disconnected: (reason) =>
                @console.log("AutoRefresh: disconnected: #{reason}")

            error: (e) =>
                @console.error("AutoRefresh: connector error #{JSON.stringify(e)}")

            message: (message) =>
                @console.log("AutoRefresh: received message #{JSON.stringify(message)}")

                name = message.name;
                action = MESSAGE_MAP[name];
                @reloader.perform(action, message.data)


        @window.addEventListener 'beforeunload', =>
            @connector.disconnect()
            return null

        @initialized = yes
