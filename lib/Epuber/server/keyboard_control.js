
window.addEventListener('keydown', function (e) {
    var l = window.location;

    switch (e.keyCode)
    {
        case 37: // left
            var previous_path = $previous_path;
            if ( previous_path )
            {
                console.log('previous page');
                l.assign('/toc/' + previous_path);
            }
            break;

        case 39: // right
            var next_path = $next_path;
            if ( next_path )
            {
                console.log('next page');
                l.assign('/toc/' + next_path);
            }

            break;
    }
});
