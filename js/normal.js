var normal = function(){
    q('form').on('change',function(e){
	e.target.style.backgroundColor = e.target.value == e.target.attr('name') ? '' : '#8f8'
    })
}
document.addEventListener("DOMContentLoaded", normal, false);

