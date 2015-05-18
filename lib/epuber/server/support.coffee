unless Object.keys
    # @param obj {Object}
    # @return {Array}
    #
    Object.keys = (obj) ->
        (k for k of obj when Object.prototype.hasOwnProperty.call(obj, k))


@after = (delay, func) ->
    setTimeout(func, delay)
