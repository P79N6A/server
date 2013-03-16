
var setup = function(){

    var x = document.querySelectorAll('div')

    document.querySelector('button').addEventListener("click",function(e){
	var f = []
	for(var i=0,l=x.length;i<l;i++)
	    if (x[i].style.backgroundColor=='lime')
		f.push(x[i].innerText)
	document.location.href=document.location.href+'&a='+f.join(',').replace(/#/g,'%23')
    },false)

    for(var i=0,l=x.length;i<l;i++){	
	x[i].addEventListener("click",function(e){
	    b=this.style.backgroundColor
	    if (b==''){
		this.style.backgroundColor='lime'
	    } else {
		this.style.backgroundColor=''}
	},false)}
}

document.addEventListener("DOMContentLoaded", setup, false);
