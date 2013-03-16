var e = function(){
    var f = q('#showQuote')
    var showQuote=function(){
	q('#quote').remove()
	if(f.attr('show')){
	    f.removeAttribute('show')
	    var s='.q {display: none}'
	    f.style.backgroundColor=''
	} else {
	    f.attr('show','quoted')
	    var s='.q {display: inline}'
	    f.style.backgroundColor='#0f0'
	}
	q('body').append(el('style').attr('id','quote').txt(s))
    }
    f.on('click',showQuote)
}
document.addEventListener("DOMContentLoaded", e, false);
