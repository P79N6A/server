document.addEventListener("DOMContentLoaded", function(){
    var q=document.querySelector('input[name=q]')
    q.addEventListener('keydown',function(e){e.stopPropagation()},false)
    q.focus()
}, false);

