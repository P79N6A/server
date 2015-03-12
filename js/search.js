document.addEventListener("DOMContentLoaded", function(){
    var search = document.querySelector('input[name=q]')
    if (search) {
	if (search.value.length==0)
	    search.focus();
	search.addEventListener('keydown',function(e){e.stopPropagation()},false)
    }
}, false);
