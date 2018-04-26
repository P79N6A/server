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
end
