class R
  module Webize
    def triplrCalendar
      cal_file = File.open pathPOSIX
      cals = Icalendar::Calendar.parse(cal_file)
      cal = cals.first
      puts cal
      event = cal.events.first
      puts event
    end
  end
end
