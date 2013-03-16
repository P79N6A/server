var d = new Date();
var t = d.getUTCHours()*100+d.getUTCMinutes()
var seek=function(n,d){
    s=String(n)
    if(document.querySelector('span[class=s'+s+']')){
	show(s)
    } else if (n < 26200 && n > 2000){seek(n+25*d,d)}}
var next=function(){seek(Number(document.querySelector('div[sho]').className.slice(1))+25,1)}
var prev=function(){seek(Number(document.querySelector('div[sho]').className.slice(1))-25,-1)}
var show=function(b){
    x=document.querySelectorAll('div[sho]')
    for(var i=0,l=x.length;i<l;i++){
	x[i].style.display='none'
	x[i].removeAttribute('sho')
    }
    x=document.querySelector('.s'+b)
    if (!x.hasAttribute('on')){
	c=x.children
	for(var i=0,l=c.length;i<l;i++){
	    var start = Number(c[i].getAttribute('s'))
	    var end = Number(c[i].getAttribute('e'))
	    if ((start <= t && ((t <= end) || end < start)) || t <= end && start > end) {c[i].className='on'}
	}
	x.setAttribute('on','dis')
    }

    x.style.display=''
    x.setAttribute('sho','w')
}
var input=function(){return document.querySelector('.input')}
var go=function(n){
    var b=String(Math.floor(Number(n) / 25) * 25)
    show(b)
    x=document.querySelectorAll('.s'+b+' > b')
    for(var i=0,l=x.length;i<l;i++){
	if(x[i].textContent==n) x[i].scrollIntoView(true)
    }

		  }
var num=function(n){
    var i= input()
    i.textContent=i.textContent+String(n)
    if(i.textContent.length > 3){
	if(!(i.textContent.length==4 && Number(i.textContent) < 2300)){n=i.textContent;i.textContent='';go(n)}
    } else if(i.textContent.length == 3){
	if (Number(i.textContent) < 200) {go(i.textContent+'00')} else {go(i.textContent+'0')}
    }
}
var setup = function(){
    if(window.location.hash.match(/^#\d+$/)) go(window.location.hash.slice(1))
/*
    document.querySelector('.prev').addEventListener("mouseover",function(){document.querySelector('.prevButton').style.display=''},false)    
    document.querySelector('.prev').addEventListener("click",function(){
	window.setTimeout(function(){document.querySelector('.prevButton').style.display='none'},8000);prev()},false)
    document.querySelector('.next').addEventListener("mouseover",function(){document.querySelector('.nextButton').style.display=''},false)    
    document.querySelector('.next').addEventListener("click",function(){
	window.setTimeout(function(){document.querySelector('.nextButton').style.display='none'},8000);next()},false)
	*/
    document.addEventListener("keydown",function(e){
	if(e.keyCode == 27 || e.keyCode == 46 || e.keyCode==8){input().textContent=''}
	if(e.keyCode >= 48 && e.keyCode <= 57){num(e.keyCode - 48)} else if(e.keyCode >= 96 && e.keyCode <= 105) {num(e.keyCode - 96)} else
	    if(e.keyCode==78){next()} else if (e.keyCode==80) {prev()}
    }, false);
    document.querySelector('table').addEventListener("mouseover",function(e){show(e.target.getAttribute('title'))},false)
}
document.addEventListener("DOMContentLoaded", setup, false);
