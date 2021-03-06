# encoding: utf-8

class MinimalMapObservation
  attr_accessor :id, :lat, :long, :location, :location_id

  def initialize(id, lat, long, location_or_id)
    @id = id
    @lat = lat
    @long = long
    if location_or_id.is_a?(Fixnum) or
       location_or_id.is_a?(String)
      @location_id = location_or_id.to_i
    elsif location
      @location = location_or_id
      @location_id = location_or_id.id
    end
  end

  def location=(loc)
    if loc
      @location = loc
      @location_id = loc.id
    else
      @location = nil
      @location_id = nil
    end
  end

  def is_location?
    false
  end

  def is_observation?
    true
  end

  def lat_long_dubious?
    lat and location and not location.lat_long_close?(lat, long)
  end
end
