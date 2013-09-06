var histogram = function(){
    var showBin =  function(e){
	q('.histBin.'+e.target.attr('class')).scrollIntoView()
    }

    var bins = document.querySelectorAll('table.histogram td');
    bins.on("click",showBin,false)
    bins.on("mouseover",showBin,false)
}

document.addEventListener("DOMContentLoaded", histogram, false)
