var pager = function(){
    document.addEventListener("keydown",function(e){
	if(e.keyCode == 78){
	    e.preventDefault();
	    document.location.href = document.querySelector('a[rel=next]').href
	} else if (e.keyCode==80) {
	    e.preventDefault();
	    document.location.href = document.querySelector('a[rel=prev]').href
	}
    }, false);
}
document.addEventListener("DOMContentLoaded", pager, false);

