document.addEventListener("DOMContentLoaded", function(){
    document.addEventListener("keydown",function(e){
	if(e.keyCode == 78)
	    document.location.href = document.querySelector('a[rel=next]').href
	if (e.keyCode==80)
	    document.location.href = document.querySelector('a[rel=prev]').href
    },false)}, false);
