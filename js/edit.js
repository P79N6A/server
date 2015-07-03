document.addEventListener("DOMContentLoaded", function(){
    document.body.addEventListener('keypress',function(e){
	console.log(e,this)
	if(e.keyCode == 27){
	    var cancel = document.querySelector('#cancel')
	    console.log('cancel edits')
	    cancel.click()
	}
    },false)

}, false);

