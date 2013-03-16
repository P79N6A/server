var audio = function(){
    var a = document.querySelector('#player')
    var r=q('#rand'),t=qa('.entry')

    var changeTrack = function(i){
	var t=decodeURIComponent(i)
	q('title').txt(t)
	a.attr('src',i).load()
	a.play()
	GET(i+'?view&un',function(d){
	    q('#data').innerHTML=d.responseText	})}

    var selecta = function(){
	if (r.hasAttribute('r')){
	    return t[Math.floor(Math.random()*t.length)]
	} else {
	    var cur = q('a[href="#'+a.attr('src')+'"]')
	    if(cur && cur.nextSibling) {
		return cur.nextSibling
	    } else {
		return q('.entry')}}}

    var at=function(p){window.location.hash=a.attr('src')+'|'+p}

    var seek = function(s){
	var p=a.currentTime+s
	if (p > a.duration){
	   p = p - a.duration
	} else if (p < 0) {
	    p = p + a.duration}
	at(p)}

    var jump = function(){var s = selecta()
	window.location.href=s.attr('href')}
    q('#jump').on("click",jump)

    var rand=function(e){
	if (r.hasAttribute('r')){
	    r.removeAttr('r').style.backgroundColor='#ddf'
	} else {
	    r.attr('r','r').style.backgroundColor='#33f'}}
    r.on("click",rand)

    qa('audio').map(function(){this.load(); this.on("ended",jump)})

    document.addEventListener("keydown",function(e){
	switch(e.keyCode){
	case 13:
	    jump();
	    break;
	case 66:
	    jump();
	    break;
	case 78:
	    jump();
	    break;
	case 80:
	    window.history.back();
	    break;
	case 37:
	    seek(-5);
	    break;
	case 39:
	    seek(5);
	    break;
	case 33:
	    seek(600);
	    break;
	case 34:
	    seek(-600);
	    break;
	case 188:
	    seek(-30);
	    break;
	case 190:
	    seek(30);
	    break;
	case 82:
	    rand();
	    break;
	case 32:
	    if(a.paused){
		a.play()
	    }else{
		at(a.currentTime)
		a.pause()}
	    e.preventDefault()
	    break;
	}},false)
    
    var hashChange = function(){
	var h=window.location.hash.slice(1).split('|')
	if(a.attr('src')!=h[0]) changeTrack(h[0]) 
	if(h[1]<a.duration) a.currentTime=h[1]}

    window.onhashchange = hashChange
    if(window.location.hash){
	hashChange()
	setTimeout(function(){
            if(a.duration){
                a.currentTime=window.location.hash.split('|')[1]
                a.play()}},1338)}}

document.addEventListener("DOMContentLoaded", audio, false);
