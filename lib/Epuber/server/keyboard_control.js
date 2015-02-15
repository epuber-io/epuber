
window.addEventListener('keydown', function (e) {
    var l = window.location;

    switch (e.keyCode)
    {
        case 37: // left
            console.log('previous page');
            l.assign('/toc/$previous_path');
            break;

        case 39: // right
            console.log('next page');
            l.assign('/toc/$next_path');
            break;
    }
});
