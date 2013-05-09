
var setup = function(){

    var x = document.querySelectorAll('div')

    document.querySelector('button').addEventListener("click",function(e){
	var f = []
	for(var i=0,l=x.length;i<l;i++){
	    if (x[i].className=='a'){
		f.push(x[i].innerHTML)
	    }
	}
	document.location.href=document.location.href+'&a='+f.join(',').replace(/#/g,'%23')
    },false)

    for(var i=0,l=x.length;i<l;i++){	
	x[i].addEventListener("click",function(e){
	    b=this.className
	    if (b==''){
		this.className='a'
	    } else {
		this.className=''}
	},false)}
}

document.addEventListener("DOMContentLoaded", setup, false);
