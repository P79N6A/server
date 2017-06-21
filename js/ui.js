N = NodeList.prototype;
E = Element.prototype;
N.map = function(f,a){for(var i=0,l=this.length;i<l;i++) f.apply(this[i],a);return this};
E.attr = function(a,v){
    if(v){ this.setAttribute(a,String(v))
	   return this
	 } else { return this.getAttribute(a)}};
var prev = null;
var first = null;
document.addEventListener("DOMContentLoaded", function(){

    // visit identified elements to construct selection ring
    document.querySelectorAll('[id]').map(function(e){
	if(!first)
	    first = this;
	this.attr('next',first.attr('id'));
	first.attr('prev',this.attr('id'));
	if(prev){
	    this.attr('prev',prev.attr('id'));
	    prev.attr('next',this.attr('id'));
	};
	prev = this;
	// bind tap-to-select handler
	this.addEventListener("click",function(e){
	    var id = this.attr('id');
	    if(window.location.hash.slice(1)==id){
		window.location = this.attr('href');
	    } else {
		window.location.hash = id;
	    };
	},false);
    });


    // keyboard navigation: <p> prev <n> next <shift-P> prev page <shift-N> next page <shift-U> up <Enter> goto
    document.addEventListener("keydown",function(e){
	
	var jumpDoc = function(direction, start) {
	    var doc = document.querySelector("head > link[rel='"+direction+"']");
	    if(doc)
		window.location = doc.getAttribute('href') + start;
	};

	var key = e.keyCode;
//	console.log(key);
	
	if(e.getModifierState("Shift")) {
	    if(key==80) // [p]revious
		jumpDoc('prev','#last');
	    if(key==78) // [n]ext
		jumpDoc('next','#first');
	    if(key==85) // [u]p
		jumpDoc('up','#first');
	    if(key==68) // [d]own
		jumpDoc('down','#first');

	    return null;
	};

	if(key==80){ // (p)revious selectable
	    loc = window.location.hash
	    if(loc) {
		cur = document.querySelector(loc);
		if(!cur)
		    cur = first;
	    } else {
		cur = first
	    };
	    var p = cur.attr('prev');
	    window.location.hash = p;
	};
	if(key==78){ // (n)ext selectable
	    var loc = window.location.hash;
	    var cur = null;
	    if(loc)
		cur = document.querySelector(loc);
	    if(!cur) {
		window.location.hash = first.attr('id');
	    } else {
		if(cur.attr('id')=='next'){
		    window.location = cur.attr('href'); // next element is on following page
		} else {
		    window.location.hash = cur.attr('next'); // next element in-page
		};
	    };
	};
	if(key==13){ // goto
	    loc = window.location.hash;
	    if(loc){
		cur = document.querySelector(loc);
		if(cur){
		    href = cur.attr('href');
		    if(href && cur.nodeName.toLowerCase() != 'a') {
			window.location = href;
		    };
		};
	    };
	};
	if(key==83){ // sort
	    var sel = document.querySelector('.selected');
	    if(sel){
		var next = sel.nextSibling || document.querySelector('tr > th[href]');
		if(next)
		    window.location = next.getAttribute('href');
	    };
	};
	if(key==82){ // reverse sort
	    window.location = document.querySelector('.selected').getAttribute('href');
	};
	if(key==27){ // exit query-context
	   window.location = window.location.pathname;
	};
    },false);

}, false);
