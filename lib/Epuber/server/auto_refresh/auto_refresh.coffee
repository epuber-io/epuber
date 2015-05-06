
# most of this code is based on https://github.com/livereload/livereload-js/blob/master/src/livereload.coffee
#

class @AutoRefresh
    MESSAGE_MAP =
        styles: ReloaderContext.ReloadType.style
        reload: ReloaderContext.ReloadType.reload
        compile_start: ReloaderContext.ReloadType.compilation_begin
        compile_end: ReloaderContext.ReloadType.compilation_end

    CONNECTION_STATUS_ID = 'epuber_connection_container'

    constructor: (@window, @console) ->
        unless @WebSocket = @window.WebSocket || @window.MozWebSocket
            @console.error("AutoRefresh disabled because the browser does not seem to support web sockets")
            return

        @document = @window.document

        @reloader = new ReloaderContext(@window, @console)

        @connector = new Connector window.location, @WebSocket, @console, Timer,
            connecting: =>
                @_displayConnectionStatus('Connecting')

            socketConnected: =>
            connected: =>
                @console.info("AutoRefresh: connection to server established")
                @_hideConnectionStatus()

            disconnected: (reason) =>
                msg = "AutoRefresh: disconnected: #{reason}"
                @console.log(msg)
                @_displayConnectionStatus(msg)

            error: (e) =>
                msg = "AutoRefresh: connector error #{JSON.stringify(e)}"
                @console.error(msg)
                @_displayConnectionStatus(msg)

            message: (message) =>
                @console.log("AutoRefresh: received message #{JSON.stringify(message)}")

                name = message.name;
                action = MESSAGE_MAP[name];
                @reloader.perform(action, message.data)


        @window.addEventListener 'beforeunload', =>
            @connector.disconnect('beforeunload')
            return null

        @initialized = yes

    _displayConnectionStatus: (statusMessage) ->
        unless @document.body?
            @window.addEventListener 'load', =>
                @_displayConnectionStatus(statusMessage)
            return

        container = @document.getElementById(CONNECTION_STATUS_ID)
        if container?
            container.parentNode.removeChild(container)

        container = @document.createElement('div')
        container.id = CONNECTION_STATUS_ID
        container.onclick = ->
            container.parentNode.removeChild(container)

        title = @document.createElement("p")
        title.innerHTML = statusMessage
        container.appendChild(title)

        if @document.body.firstChild?
            @document.body.insertBefore(container, @document.body.firstChild)
        else
            @document.body.appendChild(container)

    _hideConnectionStatus: ->
        container = @document.getElementById(CONNECTION_STATUS_ID)
        if container?
            container.parentNode.removeChild(container)
