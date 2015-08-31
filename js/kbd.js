
Element.prototype.on = function(b,f){this.addEventListener(b,f,false); return this}
NodeList.prototype.map = function(f,a){for(var i=0,l=this.length;i<l;i++) f.apply(this[i],a); return this}
NodeList.prototype.on = function(){return this.map(Element.prototype.on,arguments)}

var items = {};
var item = null;
var last = null;
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
    var selectable = document.querySelectorAll("[selectable][id]");
    selectable.map(function(){
	var id = this.getAttribute('id');
	var re = {};
	re['id'] = id;
	if(item){ // link traversible nodes
	    re['prev'] = item;
	    re['prev']['next'] = re;
	};
	items[id] = item = re;
    });
    last = item;
    selectable.on("click",focusNode);
});

// keyboard navigation
document.addEventListener("keydown",function(e){
    var resource = null;
    var id = window.location.hash.slice(1);

    if(id)
	resource = document.getElementById(id);

    if(resource) { // a resource has focus
	var prev = function() {
	    var p = items[id]['prev'];
	    if(p) { // previous item
		window.location.hash = p['id'];
	    } else { // out of previous items -> previous page
		prevDoc();
	    };
	};
	var next = function() {
	    var n = items[id]['next'];
	    if(n) { // next item
		window.location.hash = n['id'];
	    } else { // out of next-items -> next page
		nextDoc();
	    };
	};
	// key: p
	if(e.keyCode==80) {
	    e.preventDefault();
	    if (e.getModifierState("Shift")) {
		prevDoc(); // <shift-p>  previous (page)
	    } else {
		prev(); // <p>  previous (resource)
	    };
	};
	// key: n
	if(e.keyCode==78){
	    e.preventDefault();
	    if (e.getModifierState("Shift")) {
		nextDoc(); // <shift-n> next (page)
	    } else {
		next(); // <n> next (resource)
	    };
	};
	// key: tab
	if(e.keyCode==9){
	    e.preventDefault();
	    if (e.getModifierState("Shift")) {
		prev(); // <shift-tab> previous (resource)
	    } else {
		next(); // <tab> next (resource)
	    };
	};
    } else { // no resources focused
	// <n> <tab>  select first entry
	if(e.keyCode==78||e.keyCode==9) {
	    window.location.hash = document.querySelector('[selectable][id]').getAttribute('id');
	};
	// <p> select last entry
	if(e.keyCode==80) {
	    window.location.hash = last;
	};
    };
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
