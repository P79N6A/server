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
    var selectNext = function(){
	var cur = null;
	if(window.location.hash)
	    cur = document.querySelector(window.location.hash);
	if(!cur)
	    cur = last;
	window.location.hash = cur.attr('next');
    };
    var selectPrev = function(){
	var cur = null;
	if(window.location.hash)
	    cur = document.querySelector(window.location.hash);
	if(!cur)
	    cur = first;
	window.location.hash = cur.attr('prev');;
    };
    var gotoSelection = function(){
	if(window.location.hash){
	    // element
	    cur = document.querySelector(window.location.hash);
	    if(cur){
		// location
		href = cur.attr('href');
		// go
		if(href)
		    window.location = href;
	    };
	};
    };
    document.addEventListener("keydown",function(e){
	var jumpDoc = function(direction) {
	    var doc = document.querySelector("head > link[rel='"+direction+"']");
	    if(doc)
		window.location = doc.getAttribute('href');
	};
	var key = e.keyCode;
//	console.log(key);
	if(e.getModifierState("Shift")) {
	    if(key==80) // [p]rev page
		jumpDoc('prev');
	    if(key==78) // [n]ext page
		jumpDoc('next');
	};
	if(key==78) // [up] previous element
	    selectPrev();
	if(key==80) // [down] next element
	    selectNext();
	if(key==13) // [enter] select
	    gotoSelection();
    },false);
}, false);
