
goToPage = (path) ->
    window.location.assign('/book/' + path) if path?

key 'right', -> goToPage($next_path)
key 'left',  -> goToPage($previous_path)
