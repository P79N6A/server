NodeList.prototype.map = function(f,a){
    for(var i=0, l=this.length; i<l; i++)
	f.apply(this[i],a);
    return this;
};
Element.prototype.attr = function(a,v){
    if(v){
	this.setAttribute(a,String(v));
	return this;
    } else {
	return this.getAttribute(a);
    };
};
document.addEventListener("DOMContentLoaded", function(){

    var first = null;
    var last = null;

    // construct selection-ring
    document.querySelectorAll('[id]').map(function(e){
	if(!first)
	    first = this;	
	if(last){ // link
	    this.attr('prev',last.attr('id'));
	    last.attr('next',this.attr('id'));
	};
	last = this;
    });
    if(first && last){ // round the ring
	last.attr('next',first.attr('id'));
	first.attr('prev',last.attr('id'));
    };

    // keyboard navigation
    document.addEventListener("keydown",function(e){
	var key = e.keyCode;
	var selectNext = function(){
	    var cur = null;
	    if(window.location.hash)
		cur = document.querySelector(window.location.hash);
	    if(!cur)
		cur = last;
	    window.location.hash = cur.attr('next');
	    e.preventDefault();
	};
	var selectPrev = function(){
	    var cur = null;
	    if(window.location.hash)
		cur = document.querySelector(window.location.hash);
	    if(!cur)
		cur = first;
	    window.location.hash = cur.attr('prev');;
	    e.preventDefault();
	};
	var gotoLink = function(direction) {
	    var doc = document.querySelector("head > link[rel='"+direction+"']");
	    if(doc)
		window.location = doc.getAttribute('href');
	};
	var gotoHref = function(){
	    if(window.location.hash){
		cur = document.querySelector(window.location.hash);
		if(cur){
		    href = cur.attr('href');
		    if(href)
			window.location = href;
		};
	    };
	};
	if(e.getModifierState("Shift")) {
	    if(key==80) // [p]rev page
		gotoLink('prev');
	    if(key==78) // [n]ext page
		gotoLink('next');
	} else {
	    if(key==38||key==78) // [up] [p]revious element
		selectPrev();
	    if(key==40||key==80) // [down] [n]ext element
		selectNext();
	    if(key==13) // [enter] goto href
		gotoHref();
	};
    },false);
    document.querySelector('form > input').addEventListener("keydown",function(e){
	e.stopPropagation();
    },false);
}, false);
