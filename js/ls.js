var ls = function(){
    var table = document.querySelector('table.ls')
    if(table) {
	table.addEventListener("click",function(e){
	    var row = e.target.parentNode
	    var uri = row.getAttribute('uri')
	    if(uri) {
		document.location.href = uri;
	    }
	}, false);
    }
}
document.addEventListener("DOMContentLoaded", ls, false);

