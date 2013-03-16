
var scale = function(){
    document.querySelector('#scale').addEventListener("mouseover",function(e){
	if(e.target.getAttribute('class')=='bar')
	    document.location.href=e.target.parentNode.getAttribute('href')
	
    }, false);
}
document.addEventListener("DOMContentLoaded", scale, false);

