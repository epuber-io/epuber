
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

        @shouldDisplayConnectionStatus = no
        @document = @window.document

        @reloader = new ReloaderContext(@window, @console)

        url_without_fragment = new URI(window.location).fragment(null).toString()

        @connector = new Connector url_without_fragment, @WebSocket, @console, Timer,
            connecting: =>
                @console.info("AutoRefresh: started connecting")
                @_displayConnectionStatus('Connecting')

            socketConnected: =>

            connected: =>
                @console.info("AutoRefresh: connection to server established")
                @_hideConnectionStatus()

            disconnected: (reason) =>
                msg = "AutoRefresh: disconnected (reason: #{reason})"
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


        $(@window).unload =>
            @connector.disconnect('unload')

        @initialized = yes

    _displayConnectionStatus: (statusMessage) ->
        @shouldDisplayConnectionStatus = yes

        unless @document.body?
            $(@window).load =>
                if @shouldDisplayConnectionStatus
                    @_displayConnectionStatus(statusMessage)
            return

        container = @document.getElementById(CONNECTION_STATUS_ID)

        # remove if it is already there
        $(container).remove() if container?

        # create new container element
        container = @document.createElement('div')
        container.id = CONNECTION_STATUS_ID

        # remove item after user clicks on the overlay
        container.onclick = ->
            $(container).remove()

        title = @document.createElement("p")
        title.innerHTML = statusMessage
        container.appendChild(title)

        $(container).prependTo(@document.body)

    _hideConnectionStatus: ->
        @shouldDisplayConnectionStatus = no

        unless @document.body?
            $(@window).load =>
                unless @shouldDisplayConnectionStatus
                    @_hideConnectionStatus()
            return

        $("\##{CONNECTION_STATUS_ID}").remove()
