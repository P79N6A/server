var histogram = function(){
    var showBin =  function(e){
	var b = e.target.attr('class')
	q('.histBin.' + b).scrollIntoView()
//	console.log(q('.histBin.' + b))
    }

    var bins = document.querySelectorAll('table.histogram td');
    bins.on("click",showBin,false)
    bins.on("mouseover",showBin,false)
}

document.addEventListener("DOMContentLoaded", histogram, false)
