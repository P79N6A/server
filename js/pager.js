var pager = function(){
    document.addEventListener("keydown",function(e){
	if(e.keyCode == 78){
	    e.preventDefault();
	    document.location.href=q('a[rel=next]').attr('href')
	} else if (e.keyCode==80) {
	    e.preventDefault();
	    document.location.href=q('a[rel=prev]').attr('href')
	}
    }, false);
    var search = document.querySelector('input[name=q]')
    if (search)
	search.addEventListener('keydown',function(e){e.stopPropagation()},false)
}
document.addEventListener("DOMContentLoaded", pager, false);

