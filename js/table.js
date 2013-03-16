var table = function(){

    var e=q('#e > tbody')

    E.tools=function(t){
	this.append(el('td').attr('class','meta').attr('t',t).append(q('#tools').clone()).bindTools())}

    E.col=function(i){
	var c = []
	for (var r=0;r<e.rows.length-1;r++)
	    c.push(e.rows[r].cells[i])
	return c }
    E.row=function(){
	return this.parentNode.childNodes.array().slice(0,-1)
    }


    E.bindTools=function(){
	var t=this
	var col = t.attr('t') == 'col'

	t.querySelector('.cl').click(function(){
	    if(col){
		if (e.rows[0].cells.length > 2) {
		    t.col(t.cellIndex).map(function(e){
			e.remove()})
		    t.remove()}
	    } else {
		if (e.rows.length > 2)
		    t.parentNode.remove()}})

	t.on(
	 'mouseover',function(e){
	     (col ? t.col(t.cellIndex) : t.row()).map(function(e){
		     e.style.borderColor='#bbb'})
	    }
	).on(
	 'mouseout',function(e){
	     (col ? t.col(t.cellIndex) : t.row()).map(function(e){
		     e.style.borderColor=''})
	     })
	return this }

    var cell=function(){return el('td').attr('class','cell').append(q('#prototype').clone())}
    var swatch=q('#swatch')
    var setSwatch = function(e){
	if (e.target.style.backgroundColor)
	    swatch.style.backgroundColor=e.target.style.backgroundColor	
    }
    if(e){
    q('#e').on('drop',function(e) {
	var c=[],t=e.target,el=null
	if(t.className=='meta'){
	    el=t
	}else if(t.className=='cl'){
	    el=t.parentNode
	}
	if(el){
	    c=el.attr('t')=='col' ? el.col(el.cellIndex) : el.row()
	}
	c.map(function(t){
	    t.style.backgroundColor=swatch.style.backgroundColor
	})
                    return false;
    }).on('dragover',function(e){
	e.preventDefault()
    })

    q('#colors').on('mousedown',setSwatch).on('mousemove',setSwatch)

    q('#bw').click(function(){
	var b='body {background-color: black;color: white}'
	var w='body {background-color: white;color: black}'
	var r=q('#bwRules')
	r.innerText=(r.innerText == b ? w : b)
    })

    q('#addRow').click(addRow)
    q('#addCol').click(addCol)
    qa('td.meta').map(E.bindTools)
    } 

    var addRow=function(){
	var r=el('tr');	e.insertBefore(r,e.lastChild)
	for (var i=0;i<e.rows[0].childNodes.length-1;i++){
	    var c= cell()
	    r.append(c)
	    c.style.backgroundColor=e.rows[0].childNodes[i].style.backgroundColor
	}
	  
	r.tools('row')}

    var addCol=function(){
	var i=0
	for (;i<e.rows.length-1;i++){
	    var c = cell()
	    var n = e.rows[i].childNodes
	    if (n.length > 1)
		c.style.backgroundColor=n.array().slice(n.length-2,n.length-1)[0].style.backgroundColor
	    e.rows[i].insertBefore(c, e.rows[i].lastChild)

	}
	e.rows[i].tools('col')}
}

document.addEventListener("DOMContentLoaded", table, false);
