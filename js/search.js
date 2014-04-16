document.addEventListener("DOMContentLoaded", function(){
    var search = document.querySelector('input[name=q]')
    if (search) {
	search.focus()
	search.addEventListener('keydown',function(e){e.stopPropagation()},false)
    }
}, false);
