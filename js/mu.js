N=NodeList.prototype; E=Element.prototype;

GET=function(u,f){var r=new XMLHttpRequest();r.open('GET',u,true);r.onreadystatechange=function(){if(r.readyState==4){if(r.status==200)f(r)}};r.send(null)};
var el = function(e){return document.createElement(e)};
var q  = function(s){return document.querySelector(s)};
var qa = function(s){return document.querySelectorAll(s)};

N.map=function(f,a){for(var i=0,l=this.length;i<l;i++) f.apply(this[i],a);return this}
N.array=function(){
    var r=[]
    for(var i=0,l=this.length;i<l;i++){
	r.push(this[i])
    }
    return r};

E.append =function(e){this.appendChild(e); return this};
E.on     =function(b,f){this.addEventListener(b,f,false);return this};
E.click  =function(f){this.on('click',f); return this};
E.hide   =function(){ this.style.display='none'; return this};
E.show   =function(){this.style.display=''; return this};
E.attr   =function(a,v){if(v){this.setAttribute(a,String(v));return this}else{return this.getAttribute(a)}};
E.remove=function(){this.parentNode.removeChild(this)};
E.removeAttr=function(a){this.removeAttribute(a);return this};
E.attrs  =function(as){for (var a in as) this.attr(a,as[a]);return this};
E.clone=function(){return this.cloneNode(true).removeAttr('id')};

['attr','click','hide','show'].map(function(f){N[f]=function(){return this.map(E[f],arguments)}});

[['html','innerHTML'],
 ['txt','textContent']].map(function(f){E[f[0]]=function(a){if(a){this[f[1]]=a;return this} else {return this[f[1]]}}});
