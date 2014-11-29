document.addEventListener("DOMContentLoaded", function(){
    var kb = tabulator.kb;
    var subject = kb.sym(document.location.href);
    tabulator.outline.GotoSubject(subject, true, undefined, true, undefined);
}, false);
