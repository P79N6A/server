document.addEventListener("DOMContentLoaded", function(){
    document.body.addEventListener('keypress',function(e){
	console.log(e,this)
	if(e.keyCode == 27){
	    var cancel = document.querySelector('#cancel')
	    cancel.click()
	}
    },false)

}, false);

