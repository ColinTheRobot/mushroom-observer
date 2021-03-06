# encoding: utf-8
#
#  = Extensions to TimeWithZone
#
#  TimeWithZone is a Rails class that supercedes Time and DateTime.  We've
#  added these simple wrappers to standardize the formatting of dates and times
#  throughout the site.  They are also made available to the three core classes
#  (Date, Time, DateTime), just in case. 
#
#  == Instance Methods
#
#  web_date::       Format as date for website UI.
#  web_time::       Format as date-time for website UI.
#  api_date::       Format as date for API XML responses.
#  api_time::       Format as date-time for API XML responses.
#  email_date::     Format as date for emails.
#  email_time::     Format as date-time for emails.
#
################################################################################

class ActiveSupport::TimeWithZone
  Date::DATE_FORMATS[:web]   = MO.web_date_format
  Time::DATE_FORMATS[:web]   = MO.web_time_format
  Date::DATE_FORMATS[:api]   = MO.api_date_format
  Time::DATE_FORMATS[:api]   = MO.api_time_format
  Date::DATE_FORMATS[:email] = MO.email_date_format
  Time::DATE_FORMATS[:email] = MO.email_time_format

  # Format as date for API XML responses.
  def web_date; strftime(MO.web_date_format); end

  # Format as date-time for API XML responses.
  def web_time; strftime(MO.web_time_format); end

  # Format as date for API XML responses.
  def api_date; utc.strftime(MO.api_time_format); end

  # Format as date-time for API XML responses.
  def api_time; utc.strftime(MO.api_time_format); end

  # Format as date for emails.
  def email_date; strftime(MO.email_time_format); end

  # Format as date-time for emails.
  def email_time; strftime(MO.email_time_format); end

  # Format time as "5 days ago", etc.
  def fancy_time(ref=Time.now)
    diff = ref - self
    if -diff > 1.minute
      web_time
    elsif diff < 1.minute
      :time_just_seconds_ago.l
    elsif diff < 1.hour
      show_time_ago(diff/60, :minute)
    elsif diff < 1.day
      show_time_ago(diff/60/60, :hour)
    elsif diff < 1.week
      show_time_ago(diff/60/60/24, :day)
    elsif diff < 1.month
      show_time_ago(diff/60/60/24/7, :week)
    elsif diff < 1.year
      show_time_ago(diff/60/60/24*12/365.24218967, :month)
    else
      show_time_ago(diff/60/60/24/365.24218967, :year)
    end
  end

  def show_time_ago(diff, unit)
    n = diff.truncate
    if n < 2
      :"time_one_#{unit}_ago".l(:date => web_date)
    else
      :"time_#{unit}s_ago".l(:n => n, :date => web_date)
    end
  end

  # Force unit tests to verify existence of these translations.
  if false
    :time_one_minute_ago.l
    :time_one_hour_ago.l
    :time_one_day_ago.l
    :time_one_week_ago.l
    :time_one_month_ago.l
    :time_one_year_ago.l
    :time_minutes_ago.l
    :time_hours_ago.l
    :time_days_ago.l
    :time_weeks_ago.l
    :time_months_ago.l
    :time_years_ago.l
  end
end

class Time
  def web_date;   in_time_zone.web_date;   end
  def web_time;   in_time_zone.web_time;   end
  def api_date;   in_time_zone.api_date;   end
  def api_time;   in_time_zone.api_time;   end
  def email_date; in_time_zone.email_date; end
  def email_time; in_time_zone.email_time; end
  def fancy_time(*x); in_time_zone.fancy_time(*x); end
end

class DateTime
  def web_date;   in_time_zone.web_date;   end
  def web_time;   in_time_zone.web_time;   end
  def api_date;   in_time_zone.api_date;   end
  def api_time;   in_time_zone.api_time;   end
  def email_date; in_time_zone.email_date; end
  def email_time; in_time_zone.email_time; end
  def fancy_time(*x); in_time_zone.fancy_time(*x); end
end

class Date
  def web_date;   strftime(MO.web_date_format); end
  def api_date;   strftime(MO.api_date_format); end
  def email_date; strftime(MO.email_date_format); end
end
