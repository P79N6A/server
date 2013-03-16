document.addEventListener("DOMContentLoaded", function(){
    var tl;    
    var eventSource = new Timeline.DefaultEventSource(0);
    
    var theme = Timeline.ClassicTheme.create();
    theme.event.bubble.width = 350;
    theme.event.bubble.height = 300;
    var d = new Date()
    d = Timeline.DateTime.parseGregorianDateTime(d.toUTCString())
    var bandInfos = [
        Timeline.createBandInfo({
            width:          "100%", 
            intervalUnit:   Timeline.DateTime.MONTH,
            intervalPixels: 200,
            eventSource:    eventSource,
            date:           d,
            theme:          theme,
            layout:         'detailed'  // original, overview, detailed
        })
    ];
    
    tl = Timeline.create(document.getElementById("tl"), bandInfos, Timeline.HORIZONTAL);
    tl.loadJSON(t, function(json, url) {eventSource.loadJSON(json, url)});
}, false);
