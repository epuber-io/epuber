
var ckrphna = "ws://GSUB_IP_ADDRESS:GSUB_PORT";
var ckrphnba = "ws://GSUB_BONJOUR_NAME:GSUB_PORT";

var LOCALHOST_WS_URL = "ws://127.0.0.1:4567";

var WARNING_OVERLAY_ID = "lpckWarningOverlay";
var WARNING_LAG_OVERLAY_ID = "lpckLagWarningOverlay";
var spinner = null;
var spinner_container = null;


/**
 * @return {void}
 */
function saveScrollPosition() {
    var expires = new Date;
    expires.setTime(expires.getTime() + 864e5); // 240 hours

    var o = window.pageXOffset + "_" + window.pageYOffset;
    Cookies.set("epuber_scroll_offset", o, {
        expires: expires
    });
}

/**
 * @return {void}
 */
function restoreScrollPosition() {
    var e = Cookies.get("epuber_scroll_offset");
    if (e) {
        var t = e.split("_");
        if (t.length === 2) {
            window.scrollTo(parseInt(t[0]), parseInt(t[1]));
        }

        Cookies.set("epuber_scroll_offset", "0_0", {
            expires: new Date("January 01, 1970 01:01:00")
        });
    }
}

/**
 * @return {void}
 */
function windowLoadHandler() {
    restoreScrollPosition();
}

/**
 * @param type {Number}
 * @param changedFiles {Array<String>}
 */
function ckReload(type, changedFiles) {
    //if (ckRefreshIsAvailable === false) {
    //    console.warn("A refresh was requested, but the page is already refreshing. The new refresh request was ignored.");
    //    return;
    //}

    cleanupIsDone = false;
    ckRefreshIsAvailable = false;

    var i = {
        ckcup: function () {
            var isChrome = navigator.userAgent.toLowerCase().indexOf("chrome") > -1;
            var isLocal = document.URL.indexOf("file://") > -1;
            if (isChrome && isLocal) {
                setTimeout(i.ckroleicwfurl, 400)
            } else {
                i.ckrole()
            }
        },
        ckurs: function () {
            if (cleanupIsDone === true || cleanupChecksCount > 4) {
                cleanupChecksCount = 0;
                ckRefreshIsAvailable = true;
            } else {
                ++cleanupChecksCount;
                setTimeout(i.ckurs, 1500);
            }
        },
        _createCompilingOverlayIfNeeded: function () {
            if ( spinner_container ) {
                return;
            }

            spinner_container = document.createElement('div');
            spinner_container.id = 'epuber_spinner_container';
            $(spinner_container).css('opacity', '0');

            var opts = {
                lines: 12, // The number of lines to draw
                length: 7, // The length of each line
                width: 4, // The line thickness
                radius: 9, // The radius of the inner circle
                corners: 1, // Corner roundness (0..1)
                rotate: 0, // The rotation offset
                direction: 1, // 1: clockwise, -1: counterclockwise
                color: '#fff', // #rgb or #rrggbb or array of colors
                speed: 1, // Rounds per second
                trail: 42, // Afterglow percentage
                shadow: false, // Whether to render a shadow
                hwaccel: false, // Whether to use hardware acceleration
                className: 'epuber_spinner', // The CSS class to assign to the spinner
                zIndex: 2e9, // The z-index (defaults to 2000000000)
                top: '50%', // Top position relative to parent
                left: '50%' // Left position relative to parent
            };

            spinner = new Spinner(opts);
        },
        displayCompilingOverlay: function () {
            this._createCompilingOverlayIfNeeded();

            spinner.spin(spinner_container);

            $(spinner_container).appendTo('body').animate({
                opacity: '1'
            }, 200);
        },
        removeCompilingOverlay: function () {
            spinner.stop();
            $(spinner_container).remove().animate({
                opacity: '0'
            }, 200);
        }
    };

    if ( typeof ckinjectionnotpossible != "undefined" && (type === 20 || type === 30) ) {
        type = 40;
    }

    var context = new ReloaderContext(window, console);

    switch (type) {
        case 20:
            // update styles
            context.perform(ReloaderContext.ReloadType.style, changedFiles);
            break;

        case 40:
            // reload page
            saveScrollPosition();

            context.perform(ReloaderContext.ReloadType.reload, changedFiles);
            break;

        case 100:
            i.displayCompilingOverlay();
            break;

        case 110:
            i.removeCompilingOverlay();
            break;
    }
}

function warningOverlayClickHandler(e) {
    ckReload(40);
}

function lagBannerClickHandler(e) {
    lagBannerCanShow = false;
    var t = document.getElementById(WARNING_LAG_OVERLAY_ID);
    if ( t !== null ) {
        t.parentNode.removeChild(t)
    }
}

/**
 * @param useBonjour {Boolean} use bonjour address
 */
function establishckrp(useBonjour) {
    /**
     * @return {void}
     */
    function displayWarningOverlay() {
        if (!document.getElementById(WARNING_OVERLAY_ID)) {
            removeLagOverlay();

            var e = document.createElement("div");
            e.id = WARNING_OVERLAY_ID;
            e.setAttribute("style", "display:block; position:fixed; top:0px; left:0px; width:100%; background-color:red; border-bottom: 1px solid #980000; padding: 20px 0px; z-index:99999999; cursor:pointer; box-shadow: 0px 1px 5px 0px black;");
            e.setAttribute("onclick", "warningOverlayClickHandler()");
            e.innerHTML = '<p style="margin: 0 15px; color:white; font-size:20px; font-weight: medium; line-height:1.4em; font-family:sans-serif; text-align:center;">This page has lost contact with Epuber and will no longer auto-refresh.</p><p style="margin: 10px 20px; color:white; font-size:11px; line-height:1.2em; font-family:sans-serif; text-align:center;">Click this banner to reload the entire page.</p>';

            if ( document.body.firstChild ) {
                document.body.insertBefore(e, document.body.firstChild)
            }
            else {
                document.body.appendChild(e)
            }
        }
    }

    /**
     * @return {void}
     */
    function removeWarningOverlay() {
        var e = document.getElementById(WARNING_OVERLAY_ID);
        null !== e && e.parentNode.removeChild(e)
    }

    /**
     * @return {void}
     */
    function displayLagOverlay() {
        if (!document.getElementById(WARNING_OVERLAY_ID) && !document.getElementById(WARNING_LAG_OVERLAY_ID) && lagBannerCanShow === true) {
            var e = document.createElement("div");
            e.id = WARNING_LAG_OVERLAY_ID;
            e.setAttribute("style", "display:block; position:fixed; top:0px; left:0px; width:100%; background-color:orange; border-bottom: 1px solid #980000; padding: 20px 0px; z-index:99999999; cursor:pointer; box-shadow: 0px 1px 5px 0px black;");
            e.setAttribute("onclick", "lagBannerClickHandler()");
            e.innerHTML = '<p style="margin: 0 15px; color:white; font-size:20px; font-weight: medium; line-height:1.4em; font-family:sans-serif; text-align:center;">The connection to Epuber is unstable.</p><p style="margin: 10px 20px; color:white; font-size:11px; line-height:1.2em; font-family:sans-serif; text-align:center;">This page has not had contact with Epuber for 15+ seconds. This can be caused by changing networks, putting your Mac to sleep, or just a laggy LAN (e.g. public Wifi). Auto-refreshing may be slow or unreliable. Refresh manually to reconnect to Epuber or, if the connection is still working, tap this banner to hide it.</p>';
            if ( document.body.firstChild ) {
                document.body.insertBefore(e, document.body.firstChild);
            }
            else {
                document.body.appendChild(e);
            }
        }
    }

    /**
     * @return {void}
     */
    function removeLagOverlay() {
        var e = document.getElementById(WARNING_LAG_OVERLAY_ID);
        null !== e && e.parentNode.removeChild(e)
    }

    /**
     * @return {void}
     */
    function displayConnectionMessageOverlay() {
        if (!document.getElementById("lpckConMessageOverlay")) {
            var e = document.createElement("div");
            e.id = "lpckConMessageOverlay";
            e.setAttribute("style", "display:block; position:fixed; top:0px; left:0px; width:100%; background-color:orange; border-bottom: 1px solid black; padding: 20px 0px; z-index:99999999; cursor:pointer; box-shadow: 0px 1px 5px 0px black;");
            e.innerHTML = '<p style="margin: 0 15px; color:white; font-size:20px; font-weight: medium; line-height:1.4em; font-family:sans-serif; text-align:center;">Connecting to Epuber\'s refresh server...</p><p style="margin: 10px 20px; color:white; font-size:11px; line-height:1.0em; font-family:sans-serif; text-align:center;">(Auto-refreshing will not work until this completes.)</p>';

            if ( document.body.firstChild ) {
                document.body.insertBefore(e, document.body.firstChild)
            }
            else {
                document.body.appendChild(e)
            }
        }
    }

    /**
     * @return {void}
     */
    function removeConnectionMessageOverlay() {
        var e = document.getElementById("lpckConMessageOverlay");
        null !== e && e.parentNode.removeChild(e)
    }

    /**
     * @return {void}
     */
    function startHeartbeatInterval() {
        if ( null === heartbeatInterval ) {
            heartbeatInterval = setInterval(function () {
                try {
                    if ( ++missedHeartbeats > 3 ) {
                        displayLagOverlay();
                        console.warn("Epuber has not sent a heartbeat message in 15+ seconds. The connection to Epuber MAY have failed, but it is also possible that your network is simply very laggy. Auto-refreshing may be slow or unreliable.")
                    }
                } catch (e) {
                    clearInterval(heartbeatInterval);
                    heartbeatInterval = null;
                    missedHeartbeats = 0;
                    console.warn("Exception in heartbeatInterval: " + e.message)
                }
            }, 5e3)
        }
    }

    /**
     * @return {void}
     */
    function cancelHeartbeatInterval() {
        if ( heartbeatInterval !== null ) {
            clearInterval(heartbeatInterval);
            heartbeatInterval = null;
            missedHeartbeats = 0
        }
    }

    /**
     * @return {void}
     */
    function beforeWindowUnloadHandler() {
        socket.onclose = function () {};
        socket.close();
        return null;
    }

    window.WebSocket = window.WebSocket || window.MozWebSocket;

    var u;
    if ( haveTriedLocalhostForSocket === false ) {
        u = LOCALHOST_WS_URL;
    }
    else {
        u = useBonjour === true ? ckrphnba : ckrphna
    }

    ckSocketConnectionAttempts++;

    var url = window.location.href.replace(/https?:\/\//, 'ws://');
    console.log('WS: Connecting to ' + url);

    var socket = new WebSocket(url);
    setTimeout(function () {
        if (socket.readyState === 0) {
            displayConnectionMessageOverlay();
        }
    }, 1e3);
    socket.onopen = function () {
        ckSocketConnectionAttempts = 0;
        removeWarningOverlay();
        removeLagOverlay();
        removeConnectionMessageOverlay();
        startHeartbeatInterval();
    };
    socket.onerror = function (e) {
        if ( u === LOCALHOST_WS_URL && haveTriedLocalhostForSocket === false ) {
            socket.onclose = function () {};
            haveTriedLocalhostForSocket = true;
            establishckrp(false);
        }
        else {
            console.warn("Error connecting to Epuber's refresh server: " + e.message)
        }
    };
    socket.onclose = function (e) {
        if (!e.wasClean) {
            if ( null !== heartbeatInterval ) {
                displayWarningOverlay()
            }
            else if ( LOCALHOST_WS_URL === u && haveTriedLocalhostForSocket === false ) {
                haveTriedLocalhostForSocket = true;
                establishckrp(false)
            }
        }
    };
    socket.onmessage = function (e) {
        console.log('Received data `' + e.data + '`');

        var data = JSON.parse(e.data);

        missedHeartbeats = 0;
        removeLagOverlay();

        var map = {
            "styles": 20,
            "reload": 40,
            "compile_start": 100,
            "compile_end": 110
        };

        var message = data['message'];
        if ( message == 'heartbeat' )
        {
            return;
        }

        var value = map[message];
        if ( value == null )
        {
            console.error('Unknown message ' + message);
            return;
        }

        ckReload(value, data['changed_files']);
    };

    window.addEventListener("beforeunload", beforeWindowUnloadHandler, false);
    window.addEventListener("load", windowLoadHandler, false);
}

var ckRefreshIsAvailable = true;
var ckSocketConnectionAttempts = 0;
var haveTriedLocalhostForSocket = false;
var previewPathAddition = null;
var heartbeatInterval = null;
var missedHeartbeats = 0;
var lagBannerCanShow = true;
var cleanupIsDone = true;
var cleanupChecksCount = 0;

establishckrp(false);
