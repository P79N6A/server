var sw = function(){
    var l = q('.loc')
    var loc = function(e){
	if(e.target.hasAttribute('f')){
	    var f=e.target.getAttribute('f')
	    l.style.left=e.pageX+4+'px'
	    l.style.top=e.pageY-22+'px'
	    l.innerHTML=f
	    var n = qa('div[f="'+f+'"]')
	    var t = e.pageX / 4.0
	    var d = ['<br>'];
	    n.map(function(){
		var i=this.hasAttribute('t')&&(this.getAttribute('t')+'<br>')||'';
		var begin=Number(this.hasAttribute('b')&&this.getAttribute('b')||0)
	     	  var end=Number(this.hasAttribute('e')&&this.getAttribute('e')||0)
		if((begin < t) && (t < end))
		    d.push(i)})
	    l.append(el('span').attr('class','l').html(d.join('')))
	}
    }
    l.click(function(){l.innerHTML=''})
    q('#scales').click(function(e){
	q('#spectrum').style.height=e.target.innerText+'px'
    })
    q('body').on('mouseover',loc).click(loc)
    var clock = q('#clock'), t=q('#t')
    var c = function(u){
	var a=new Date()
	var h = a.getUTCHours()
	var m = a.getUTCMinutes()
	var s = a.getUTCSeconds()
	if ((s < 8) || u){
	    t.style.left=((h*60)+m)*4-21+'px'
	}
	clock.innerText=[h,(m < 10 ? '0'+m : m),(s < 10 ? '0'+s : s)].join(':')
	return false
    }
    window.setInterval(c,1000)
    clock.click(function(){t.scrollIntoView()})
    c(true);t.scrollIntoView()
};

document.addEventListener("DOMContentLoaded", sw, false);
