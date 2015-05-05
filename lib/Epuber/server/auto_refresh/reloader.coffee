
class @Timer
    constructor: (@func) ->
        @running = no; @id = null
        @_handler = =>
            @running = no
            @id = null
            @func()

    start: (timeout) ->
        clearTimeout @id if @running
        @id = setTimeout @_handler, timeout
        @running = yes

    stop: ->
        if @running
            clearTimeout @id
            @running = no; @id = null

Timer.start = (timeout, func) ->
    setTimeout func, timeout

generateCacheBustUrl = (url) ->
    URI(url).setQuery('now', 1 * new Date).toString()


unless URI.prototype.updateEmptyParts
    URI.prototype.updateEmptyParts = (location) ->
        this.hostname(location.hostname) if this.hostname() == ''
        this.port(location.port) if this.port() == ''
        this.protocol(location.protocol) if this.protocol() == ''
        return this


class @ReloaderContext
    'use strict';

    STYLE_ID = "EpuberAutoRefreshTransitionRule"
    TRANSITION =
        className: 'epuber_loading'
        duration: 0.3

    @ReloadType = ReloadType =
        style: 1
        reload: 2
        compilation_begin: 3
        compilation_end: 4


    constructor: (@window, @console) ->
        @document = @window.document
        @window.addEventListener('load', (=> @_restoreScrollPosition), false)


    _head: ->
        @__head ||= @document.getElementsByTagName('head')[0]


    _startAnimatedStylesheetReload: ->
        return if @document.getElementById(STYLE_ID)?

        style = @document.createElement("style")
        @_head().appendChild(style)

        style.setAttribute("type", "text/css")
        style.setAttribute("id", STYLE_ID)

        style_code = """
            .#{TRANSITION.className} * {
                -webkit-transition: all #{TRANSITION.duration}s ease-out;
                -moz-transition: all #{TRANSITION.duration}s ease-out;
                -o-transition: all #{TRANSITION.duration}s ease-out;
                transition: all #{TRANSITION.duration}s ease-out;
            }
        """

        if style.styleSheet
            style.styleSheet.cssText = style_code
        else
            style.appendChild(@document.createTextNode(style_code))

        @_addTransitionClassToHtmlNode()

    _stopAnimatedStylesheetReload: ->
        element = @document.getElementById(STYLE_ID)
        @_head().removeChild(element) if element?

        @_removeTransitionClassFromHtmlNode()



    _addTransitionClassToHtmlNode: ->
        htmlNode = document.body.parentNode
        htmlNode.className = htmlNode.className.replace(TRANSITION.className, "") + " #{TRANSITION.className}"

    _removeTransitionClassFromHtmlNode: ->
        htmlNode = document.body.parentNode
        htmlNode.className = htmlNode.className.replace(TRANSITION.className, "")


    _reattachAllStylesheetLinks: (changed_files_hrefs = null) ->
        links = (link for link in @document.getElementsByTagName('link') when link.rel.match(/^stylesheet$/i) and not link.__pendingRemoval)

        if changed_files_hrefs?
            changed_uris = (URI(href).updateEmptyParts(@window.location) for href in changed_files_hrefs)

            filtered_list = []
            for link in links
                uri = URI(link.href).removeQuery('now')

                for changed_uri in changed_uris
                    if uri.equals(changed_uri)
                        filtered_list.push(link)
                        break

            links = filtered_list

        for link in links
            @_reattachStylesheetLink(link)

    _reattachStylesheetLink: (link) ->
        # ignore LINKs that will be removed by LR soon
        return if link.__pendingRemoval
        link.__pendingRemoval = yes

        clone = link.cloneNode(false)
        clone.href = generateCacheBustUrl(link.href)

        # insert the new LINK before the old one
        parent = link.parentNode
        if parent.lastChild is link
            parent.appendChild(clone)
        else
            parent.insertBefore clone, link.nextSibling

        @_waitUntilCssLoads clone, =>
            if /AppleWebKit/.test(navigator.userAgent)
                additionalWaitingTime = 5
            else
                additionalWaitingTime = 200

            Timer.start additionalWaitingTime, =>
                return if !link.parentNode
                link.parentNode.removeChild(link)
                clone.onreadystatechange = null

                @window.StyleFix?.link(clone)


    _waitUntilCssLoads: (clone, func) ->
        callbackExecuted = no

        executeCallback = =>
            return if callbackExecuted
            callbackExecuted = yes
            func()

        # supported by Chrome 19+, Safari 5.2+, Firefox 9+, Opera 9+, IE6+
        # http://www.zachleat.com/web/load-css-dynamically/
        # http://pieisgood.org/test/script-link-events/
        clone.onload = =>
            @console.log "AutoRefresh: the new stylesheet has finished loading... for file #{clone.href}"
            @knownToSupportCssOnLoad = yes
            executeCallback()

        unless @knownToSupportCssOnLoad
            # polling
            do poll = =>
                if clone.sheet
                    @console.log "AutoRefresh: is polling until the new CSS finishes loading... for file #{clone.href}"
                    executeCallback()
                else
                    Timer.start 50, poll

        # fail safe
        Timer.start (10 * 1000), executeCallback

    _createCompilingOverlayIfNeeded: ->
        if @spinner_container?
            return

        @spinner_container = document.createElement('div');
        @spinner_container.id = 'epuber_spinner_container';
        $(@spinner_container).css('opacity', '0');

        opts =
            lines: 12 # The number of lines to draw
            length: 7 # The length of each line
            width: 4 # The line thickness
            radius: 9 # The radius of the inner circle
            corners: 1 # Corner roundness (0..1)
            rotate: 0 # The rotation offset
            direction: 1 # 1: clockwise, -1: counterclockwise
            color: '#fff' # #rgb or #rrggbb or array of colors
            speed: 1 # Rounds per second
            trail: 42 # Afterglow percentage
            shadow: false # Whether to render a shadow
            hwaccel: false # Whether to use hardware acceleration
            className: 'epuber_spinner' # The CSS class to assign to the spinner
            zIndex: 2e9 # The z-index (defaults to 2000000000)
            top: '50%' # Top position relative to parent
            left: '50%' # Left position relative to parent

        @spinner = new Spinner(opts)

    _displayCompilingOverlay: ->
        @_createCompilingOverlayIfNeeded()
        @spinner.spin(@spinner_container)
        $(@spinner_container).appendTo('body').animate({opacity: '1'}, TRANSITION.duration * 1000)

    _hideCompilingOverlay: ->
        @spinner.stop()
        $(@spinner_container).remove().animate({opacity: '0'}, TRANSITION.duration * 1000)



    _saveScrollPosition: ->
        expires = new Date;
        expires.setTime(expires.getTime() + 864e5)

        o = window.pageXOffset + "_" + window.pageYOffset;
        Cookies.set('epuber_scroll_offset', o, expires: expires)

    _restoreScrollPosition: ->
        offset = Cookies.get('epuber_scroll_offset')
        if offset?
            t = offset.split("_")

            if t.length == 2
                @window.scrollTo(parseInt(t[0]), parseInt(t[1]))

        Cookies.set('epuber_scroll_offset', '0_0')


    perform: (type, changed_files_hrefs) ->
        switch type
            when ReloadType.style
                @console.log('ReloadType.style')
                @_hideCompilingOverlay()

                @_startAnimatedStylesheetReload()
                @_reattachAllStylesheetLinks(changed_files_hrefs)
                after(TRANSITION.duration * 1000, => @_stopAnimatedStylesheetReload())

            when ReloadType.reload
                @console.log('AutoRefresh: reloading page')
                @_saveScrollPosition()

                uri = URI(@window.location)
                uri.setQuery('cache_control', Math.round(+new Date / 1e3))
                @window.location.assign(uri.toString())

            when ReloadType.compilation_begin
                @_displayCompilingOverlay()

            when ReloadType.compilation_end
                @_hideCompilingOverlay()

            else
                @console.error "Unsupported reload type #{type}"
