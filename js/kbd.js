
Element.prototype.on = function(b,f){this.addEventListener(b,f,false); return this}
NodeList.prototype.map = function(f,a){for(var i=0,l=this.length;i<l;i++) f.apply(this[i],a); return this}
NodeList.prototype.on = function(){return this.map(Element.prototype.on,arguments)}

var jumpDoc = function(direction, start) {
    var doc = document.querySelector("head > link[rel='"+direction+"']");
    if(doc)
	window.location = doc.getAttribute('href') + start;
};
var prevDoc = function() {jumpDoc('prev','#last')}
var nextDoc = function() {jumpDoc('next','#first')}

var focusNode = function(e){window.location.hash = this.getAttribute("id")};

var items = {};
var prior = null;
var first = null;
var last = null;
document.addEventListener("DOMContentLoaded", function(){
    var loc = window.location.hash.slice(1);
    var selectable = document.querySelectorAll("[selectable][id]");
    selectable.on("click",focusNode);

    // navigable (whitelisted via @selectable) nodes
    // first node
    first = selectable[0].getAttribute('id');
    if(loc=='first')
	window.location.hash = first;

    // link adjacent traversibles
    selectable.map(function(){
	var id = this.getAttribute('id');
	var re = {};
	re['id'] = id;
	if(prior){
	    re['prev'] = prior;
	    re['prev']['next'] = re;
	};
	items[id] = prior = re;
    });
    
    // last node
    last = prior['id'];
    if(loc=='last')
	window.location.hash = last;
});

// keyboard control
document.addEventListener("keydown",function(e){
    var href = null;
    var resource = null;
    var key = e.keyCode;
    var id = window.location.hash.slice(1);
    if(id)
	resource = document.getElementById(id)
    if(resource) { // selection exists

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
	if((key==80)||(key==38)) {
	    if (e.getModifierState("Shift")) {
		prevDoc(); // <shift-p>  previous (page)
	    } else {
		prev(); // <p>  previous (resource)
	    };
	};
	// key: n
	if((key==78)||(key==40)){
	    if (e.getModifierState("Shift")) {
		nextDoc(); // <shift-n> next (page)
	    } else {
		next(); // <n> next (resource)
	    };
	};
	// key: tab
	if(key==9){
	    if (e.getModifierState("Shift")) {
		prev(); // <shift-tab> previous (resource)
	    } else {
		next(); // <tab> next (resource)
	    };
	};
	// key: enter
	if(key==13) {
	    var href = resource.getAttribute('href');
	    if(href)
		window.location.href = href;
	};
    } else { // nothing selected
	if(key==40||key==78) {
	    window.location.hash = first;
	};
    };
},false);

window.addEventListener("hashchange",function(e){
    var id = window.location.hash.slice(1);
    var resource = document.getElementById(id);
    if(resource) {
	var resTitle = resource.getAttribute('href');
	document.querySelector('title').innerText = resTitle;
	var pointer = document.querySelector('#pointer');
	if(pointer)
	    pointer.remove();
	var ptr = document.createElement('div');
	ptr.setAttribute('id','pointer');
	ptr.innerHTML = '&rarr;';
	resource.appendChild(ptr);
    };
});
