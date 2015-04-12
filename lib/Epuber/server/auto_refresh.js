
// ------------ Support functions --------------------------------------

if (!Object.keys) {
    /**
     * @param obj {Object}
     * @return {Array}
     */
    Object.keys = function (obj) {
        var keys = [];
        for (var k in obj) {
            if (Object.prototype.hasOwnProperty.call(obj, k)) {
                keys.push(k);
            }
        }
        return keys;
    };
}



var ckrphna = "ws://GSUB_IP_ADDRESS:GSUB_PORT";
var ckrphnba = "ws://GSUB_BONJOUR_NAME:GSUB_PORT";
var ckrislocal1 = "://GSUB_IP_ADDRESS:GSUB_PORT";
var ckrislocal2 = "GSUB_BONJOUR_NAME:GSUB_PORT";

var LOCALHOST_WS_URL = "ws://127.0.0.1:4567";

var WARNING_OVERLAY_ID = "lpckWarningOverlay";
var WARNING_LAG_OVERLAY_ID = "lpckLagWarningOverlay";
var spinner = null;
var spinner_container = null;


function updateQueryString(e, t, n) {
    var o = new RegExp("(\\?|\\&)" + t + "=.*?(?=(&|$))"), i = e.toString().split("#"), r = i[0], a = i[1], l = /\?.+$/, c = r;
    return c = o.test(r) ? r.replace(o, "$1" + t + "=" + n) : l.test(r) ? r + "&" + t + "=" + n : r + "?" + t + "=" + n, a && (c += "#" + a), c
}

/**
 * @param key {String}
 * @param value {String}
 * @param [expires] {Date}
 * @param [path] {String}
 * @param [domain] {String}
 * @param [secure] {Boolean}
 */
function lpckSetCookie(key, value, expires, path, domain, secure) {
    expires = expires || new Date;

    var expiresPart = "undefined" == typeof expires ? "" : "; expires=" + expires.toGMTString();
    var pathPart = "undefined" == typeof path ? "" : "; path=" + path;
    var domainPart = "undefined" == typeof domain ? "" : "; domain=" + domain;
    var securePart = "undefined" == typeof secure ? "" : "; secure";

    document.cookie = key + "=" + encodeURIComponent(value) + expiresPart + pathPart + domainPart + securePart;
}

/**
 * @param e {Number}
 * @return {String}
 */
function lpckGetCookieVal(e) {
    var t = document.cookie.indexOf(";", e);
    if (-1 === t) {
        t = document.cookie.length;
    }
    return decodeURIComponent(document.cookie.substring(e, t))
}

/**
 * @param key {String}
 * @return {String}
 */
function lpckGetCookie(key) {
    var t = key + "=";
    for (var i = 0; document.cookie.length > i;) {
        var r = i + t.length;
        if (t === document.cookie.substring(i, r)) {
            return lpckGetCookieVal(r);
        }

        i = document.cookie.indexOf(" ", i) + 1;

        if (i === 0) {
            break;
        }
    }
    return null;
}

/**
 * @return {void}
 */
function saveScrollPosition() {
    var expires = new Date;
    expires.setTime(expires.getTime() + 864e5); // 240 hours

    var o = window.pageXOffset + "_" + window.pageYOffset;
    lpckSetCookie("ckrp_ypos", o, expires)
}

/**
 * @return {void}
 */
function windowLoadHandler() {
    var e = lpckGetCookie("ckrp_ypos");
    if (e) {
        var t = e.split("_");
        if (t.length === 2) {
            window.scrollTo(parseInt(t[0]), parseInt(t[1]));
        }

        lpckSetCookie("ckrp_ypos", "0_0", new Date("January 01, 1970 01:01:00"));
    }
}

/**
 * @param type {Number}
 */
function ckReload(type) {
    //if (ckRefreshIsAvailable === false) {
    //    console.warn("A refresh was requested, but the page is already refreshing. The new refresh request was ignored.");
    //    return;
    //}

    cleanupIsDone = false;
    ckRefreshIsAvailable = false;

    var allCSSLinkNodes = {};
    var allStyleOwnerNodes = {};
    var o = 0;
    var i = {

        /**
         * @param startAnimation {Boolean}
         */
        updateStyles: function (startAnimation) {

            /**
             * @param url {String}
             * @return {Boolean}
             */
            function checkCSSUrl(url) {
                var regexp = new RegExp("^\\.|^/(?!/)|^[\\w]((?!://).)*$|" + document.location.host + "|" + ckrislocal1 + "|" + ckrislocal2);
                return regexp.test(url);
            }

            var head = document.getElementsByTagName("head")[0];
            var STYLE_ID = "LPCodeKitLiveTransitionRule";

            if (startAnimation === true) {
                if (!document.getElementById(STYLE_ID)) {
                    var style = document.createElement("style");
                    var a = "transition: all .3s ease-out;";
                    var l = [".lpcodekit-loading * { ", a, " -webkit-", a, "-moz-", a, "-o-", a, "}"].join("");

                    style.setAttribute("type", "text/css");
                    style.setAttribute("id", STYLE_ID);
                    head.appendChild(style);

                    if ( style.styleSheet ) {
                        style.styleSheet.cssText = l;
                    } else {
                        style.appendChild(document.createTextNode(l));
                    }
                }
            } else {
                var c = document.getElementById(STYLE_ID);
                if ( c ) {
                    head.removeChild(c)
                }
            }

            for (var i = 0; i < document.styleSheets.length; i++) {
                var styleSheet = document.styleSheets[i];

                if (styleSheet) {
                    var mediaText = styleSheet.mediaText;
                    var href = styleSheet.href;

                    if (href && checkCSSUrl(href)) {
                        if (href.search(/ckMarkedForRemoval/i) === -1) {
                            // if ckMarkedForRemoval not found

                            var cssPathAndParams = href.split("?");
                            var cssPath = cssPathAndParams[0];
                            var params = cssPathAndParams.length > 1 ? cssPathAndParams[1] : "";
                            params = params.replace(/(&)?now=[0-9]*/gi, "");
                            params = params.length > 0 ? "?" + params + "&now=" + 1 * new Date : "?now=" + 1 * new Date;

                            var htmlNode = document.body.parentNode;
                            htmlNode.className = htmlNode.className.replace(/\s*lpcodekit\-loading/gi, "") + " lpcodekit-loading";

                            var link = document.createElement("link");
                            link.setAttribute("type", "text/css");
                            link.setAttribute("rel", "stylesheet");
                            link.setAttribute("href", cssPath + params);
                            if ( mediaText ) {
                                link.setAttribute("media", mediaText);
                            }

                            var ownerNode = styleSheet.ownerNode;
                            if ( ownerNode.id ) {
                                link.setAttribute("id", ownerNode.id);
                            }

                            var parentNode = ownerNode.parentNode;
                            var nextSibling = ownerNode.nextSibling;

                            if ( nextSibling ) {
                                parentNode.insertBefore(link, nextSibling)
                            }
                            else {
                                parentNode.appendChild(link)
                            }

                            allCSSLinkNodes[cssPath] = link;
                            allStyleOwnerNodes[cssPath] = ownerNode;

                            if ( /firefox/i.test(navigator.userAgent) ) {
                                ownerNode.setAttribute("href", "ckMarkedForRemoval" + href)
                            }
                        }
                    }
                }
            }
        },
        removeClassFromHtmlNode: function () {
            var e = document.body.parentNode;
            e.className = e.className.replace(/\s*lpcodekit\-loading/gi, "")
        },
        ckrole: function () {

            if (o > 100) {

                // remove all ownerNodes
                for (var url in allStyleOwnerNodes) {
                    var r = allStyleOwnerNodes[url];
                    r.parentNode.removeChild(r);
                    delete allStyleOwnerNodes[url]
                }

                console.warn("Epuber told this page to refresh its stylesheets, but one or more did not download correctly from the preview server. This is almost always caused by a laggy LAN. (Are you on public WiFi?) The page's state may not reflect your latest changes. Reload it manually or save your file again to have Epuber attempt another stylesheet injection.");
                cleanupIsDone = true;
                i.removeClassFromHtmlNode();

                return;
            }

            for (var cssUrl in allStyleOwnerNodes) {
                var linkNode = allCSSLinkNodes[cssUrl];
                var ownerNode = allStyleOwnerNodes[cssUrl];

                try {
                    var s = linkNode.sheet || linkNode.styleSheet;
                    var d;

                    if ( typeof s != 'undefined' ) {
                        d = s.rules || s.cssRules;
                    }

                    if (!s || !d) {
                        o++;
                        setTimeout(i.ckrole, 50);
                        return;
                    }

                    if (d.length > 0) {
                        o = 0;
                        ownerNode.parentNode.removeChild(ownerNode);
                        delete allStyleOwnerNodes[cssUrl];
                    }
                    else {
                        o++;
                        setTimeout(i.ckrole, 50)
                    }
                } catch (u) {
                    console.log("Exception in CKROLE: " + u);
                    o++;
                    setTimeout(i.ckrole, 50);
                    return;
                }
            }

            if (Object.keys(allStyleOwnerNodes).length === 0) {
                cleanupIsDone = true;
                setTimeout(i.removeClassFromHtmlNode, 50);
            }
        },
        ckroleicwfurl: function () {
            for (var cssUrl in allStyleOwnerNodes) {
                var t = allStyleOwnerNodes[cssUrl];
                t.parentNode.removeChild(t);
                delete allStyleOwnerNodes[cssUrl];
                setTimeout(i.removeClassFromHtmlNode, 100)
            }
        },
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

    switch (type) {
        case 20:
            // start animation
            i.updateStyles(true);
            setTimeout(i.ckcup, 70);
            setTimeout(i.ckurs, 2e3);
            break;

        case 30:
            // end animation
            i.updateStyles(false);
            setTimeout(i.ckcup, 70);
            setTimeout(i.ckurs, 2e3);
            break;

        case 40:
            // reload page
            var r = Math.round(+new Date / 1e3);
            var a = updateQueryString(window.location, "ckcachecontrol", r);
            saveScrollPosition();
            window.location.assign(a);
            break;

        case 50:
            var l = window.location.host;
            window.location.assign(previewPathAddition ? "http://" + l + "/" + previewPathAddition : "http://" + l);
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

        var n = e.data.split(/[;]{3}/);

        missedHeartbeats = 0;
        removeLagOverlay();

        switch (n[0]) {

            case"ia":
                ckReload(20);
                break;

            case"ina":
                ckReload(30);
                break;

            case"r":
                ckReload(40);
                break;

            case "compile_start":
                ckReload(100);
                break;

            case "compile_end":
                ckReload(110);
                break;

            case"rtr":
                previewPathAddition = (typeof n[1] == "undefined" ? n[1] : null);
                ckReload(50);
                break;

            case"sd":
                // probably closing
                cancelHeartbeatInterval();
                socket.onclose = function () {};
                socket.close();
                displayWarningOverlay();
        }
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
