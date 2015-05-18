
goToPage = (path) ->
    window.location.assign('/toc/' + path) if path?

key 'right', -> goToPage($next_path)
key 'left',  -> goToPage($previous_path)
