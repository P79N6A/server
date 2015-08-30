
Element.prototype.on = function(b,f){this.addEventListener(b,f,false); return this}
NodeList.prototype.map = function(f,a){for(var i=0,l=this.length;i<l;i++) f.apply(this[i],a); return this}
NodeList.prototype.on = function(){return this.map(Element.prototype.on,arguments)}

var items = {};
var item = null;
var jumpDoc = function(direction) {
    var doc = document.querySelector("head > link[rel='"+direction+"']");
    if(doc)
	window.location = doc.getAttribute('href');
};
var prevDoc = function() {jumpDoc('prev');}
var nextDoc = function() {jumpDoc('next');}
var focusNode = function(e){
    var loc = window.location.hash.slice(1);
    var id = this.getAttribute("id");
    if(loc == id && this.hasAttribute('href')){ // double-tap, goto item
	window.location = this.getAttribute('href');
    } else {
	window.location.hash = id;
    };
    e.stopPropagation();
};

document.addEventListener("DOMContentLoaded", function(){

    // selectable items
    var selectable = document.querySelectorAll("[selectable][id]");
    // build traversible-network
    selectable.map(function(){
	var id = this.getAttribute('id');
	var re = {};
	re['id'] = id;
	if(item){
	    re['prev'] = item;
	    re['prev']['next'] = re;
	};
	items[id] = item = re;
    });
    // tap-to-select
    selectable.on("click",focusNode);
});
			  
// keyboard navigation
document.addEventListener("keydown",function(e){
    var resource = null;
    var id = window.location.hash.slice(1);
    if(id)
	resource = document.getElementById(id);
    var prev = function() {
	if(resource) {
	    var p = items[id]['prev'];
	    if(p) { // previous item
		window.location.hash = p['id'];
	    } else { // out of previous items -> previous page
		prevDoc();
	    };
	}
    };
    var next = function() {
	if(resource) {
	    var n = items[id]['next'];
	    if(n) { // next item
		window.location.hash = n['id'];
	    } else { // out of next-items -> next page
		nextDoc();
	    };
	}
    };

    if(e.keyCode==80) {
	e.preventDefault();
	if (e.getModifierState("Shift")) {
	    prevDoc(); // <shift-p>  previous (doc)
	} else {
	    prev(); // <p>  previous (resource)
	};
    };
    if(e.keyCode==78){
	e.preventDefault();
	if (e.getModifierState("Shift")) {
	    nextDoc(); // <shift-n> next (doc)
	} else {
	    next(); // <n> next (resource)
	};
    };
    if(e.keyCode==9){
	e.preventDefault();
	if (e.getModifierState("Shift")) {
	    prev(); // <shift-tab> previous (resource)
	} else {
	    next(); // <tab> next (resource)
	};
    };

    if(e.keyCode==66) // <b>  back
	window.history.back();
    if(e.keyCode==70) // <f>  forward
	window.history.forward();

},false);

window.addEventListener("hashchange",function(e){
    var id = window.location.hash.slice(1);
    var resource = document.getElementById(id);
    if(resource) {
	var resTitle = resource.getAttribute('href');
	document.querySelector('title').innerText = resTitle;
	window.scrollTo(resource.offsetLeft + (resource.clientWidth / 2) - (window.width / 2), window.scrollY);
    };
});
