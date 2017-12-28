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

    // link selection-ring
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

    var firstI = null;
    var lastI = null;
    // primary-items-only selection-ring
    document.querySelectorAll('[id][primary]').map(function(e){
	if(!firstI)
	    firstI = this;
	if(lastI){ // link
	    this.attr('prevI',lastI.attr('id'));
	    lastI.attr('nextI',this.attr('id'));
	};
	lastI = this;
    });
    if(firstI && lastI){ // round the ring
	lastI.attr('nextI',firstI.attr('id'));
	firstI.attr('prevI',lastI.attr('id'));
    };

    // keyboard navigation
    document.addEventListener("keydown",function(e){
	var key = e.keyCode;
	var selectNextLink = function(){
	    var cur = null;
	    if(window.location.hash)
		cur = document.querySelector(window.location.hash);
	    if(!cur)
		cur = last;
	    window.location.hash = cur.attr('next');
	    e.preventDefault();
	};
	var selectPrevLink = function(){
	    var cur = null;
	    if(window.location.hash)
		cur = document.querySelector(window.location.hash);
	    if(!cur)
		cur = first;
	    window.location.hash = cur.attr('prev');;
	    e.preventDefault();
	};
	var selectNextItem = function(){
	    var cur = null;
	    if(window.location.hash)
		cur = document.querySelector(window.location.hash);
	    if(!cur)
		cur = lastI;
	    window.location.hash = cur.attr('nextI');
	    e.preventDefault();
	};
	var selectPrevItem = function(){
	    var cur = null;
	    if(window.location.hash)
		cur = document.querySelector(window.location.hash);
	    if(!cur)
		cur = firstI;
	    window.location.hash = cur.attr('prevI');;
	    e.preventDefault();
	};
	var gotoLink = function(arc) {
	    var doc = document.querySelector("link[rel='" + arc + "']");
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
	    if(key==38) // [p]rev superitem (subject URI)
		selectPrevItem();
	    if(key==40) // [n]ext superitem
		selectNextItem();
	    if(key==85) // [u]p to parent
		gotoLink('up');
	    if(key==68) // [d]own to children
		gotoLink('down');
	} else {
	    if(key==39 )
		console.log(e,e.target)
	    if(key==38 || key==80) // u[p]rev item (object URI)
		selectPrevLink();
	    if(key==40 || key==78) // dow[n]ext item
		selectNextLink();
	    if(key==83) // [s]ort entries
		gotoLink('sort');
	};
    },false);
    document.querySelector('form > input').addEventListener("keydown",function(e){
	if(e.keyCode != 38 && e.keyCode != 40)
	    e.stopPropagation();
    },false);
}, false);

//		window.location = e.target(getAttribute('href'));
