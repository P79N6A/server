var images = function(){
    qa('img').map(function(){
	this.on('error',E.remove).on('load',function(){
	    var m=17
	    if(this.naturalHeight<m||this.naturalWidth<m)
		this.hide()})})}

document.addEventListener("DOMContentLoaded", images, false);

