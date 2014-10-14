var ls = function(){
    document.addEventListener("keydown",function(e){

	if(e.keyCode == 38){
	    console.log('up')
	    
	} else if (e.keyCode==40) {
	    console.log('down')

	}
    }, false);
}
document.addEventListener("DOMContentLoaded", ls, false);

