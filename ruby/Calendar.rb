class WebResource
  module Webize
# TODO ICal
    def triplrCalendar
      cal_file = File.open localPath
      cals = Icalendar::Calendar.parse(cal_file)
      cal = cals.first
      puts cal
      event = cal.events.first
      puts event
    end
  end
  module HTML
    Group['decades'] = -> graph {
      decades = {}
      other = []
      
      {'uri' => '/', Type => [R[Container]],
       Contains => (decades.values.concat other)}}
  end
end
