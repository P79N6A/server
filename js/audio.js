var audio = function(){

    var track = 'td[property="uri"] a'
    var audio = document.querySelector('#media')
    var random = q('#rand')
    var trax = qa(track)

    var changeTrack = function(i,t){
	var track = decodeURIComponent(i)
	q('title').txt(track)
	q('#info').txt(track).attr('href',track+'?view=base')
	audio.src = i
	audio.attr('time',t)
	audio.load()}

    var updatePosition = function(p){
	window.location.hash = audio.attr('src')+'|'+p}

    var seek = function(s){
	var p = audio.currentTime + s
	if (p > audio.duration){
	   p = p - audio.duration
	} else if (p < 0) {
	    p = p + audio.duration}
	updatePosition(p)}

    var jump = function(){
	var s
	if (random.hasAttribute('r')){
	   s = trax[Math.floor(Math.random()*trax.length)]
	} else {
	    var cur = q(track+'[href="'+audio.attr('src')+'"]')
	    if(cur && (s = cur.parentNode.parentNode.nextSibling.querySelector(track))) {
		// next found
	    } else {
		s = q(track)
	    }
	}
	window.location.hash = s.attr('href')}

    var toggleRand = function(e){
	if (random.hasAttribute('r')){
	    random.removeAttr('r').style.backgroundColor='#ddf'
	} else {
	    random.attr('r','r').style.backgroundColor='#33f'}}

    var hashChange = function(){
	var h = window.location.hash.slice(1).split('|')
	var track = h[0]
	var   pos = h[1]
	if(audio.attr('src') != track) changeTrack(track,pos)
	if(pos < audio.duration) audio.currentTime=pos}

    random.on("click",toggleRand)
    q('#jump').on("click",jump)
    audio.on("ended",jump)
    if(window.location.hash) hashChange()
    window.onhashchange = hashChange
    trax.on('click',function(e){
	window.location.hash = e.target.parentNode.attr('href')
	e.preventDefault()
	return false
    })
    audio.on('canplay',function(){
	audio.play()
	audio.currentTime = audio.attr('time')
    })
    
    
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
	    e.preventDefault();
	    break;
	case 39:
	    seek(5);
	    e.preventDefault();
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
	    toggleRand();
	    break;
	case 32:
	    if(audio.paused){
		audio.play()
	    }else{
		updatePosition(audio.currentTime)
		audio.pause()}
	    e.preventDefault()
	    break;
	}},false)}

document.addEventListener("DOMContentLoaded", audio, false);
