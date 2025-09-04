class Vehicle
  attr_reader :make, :model, :started

  def initialize(make, model)
    @make = make
    @model = model
    @started = false
  end

  def start
    @started = true
  end

  def stop
    @started = false
  end

  def started?
    @started
  end

  def remaining_fuel(miles)
    mpg = 2
    fuel_used = miles.to_f / mpg
    @fuel_level -= fuel_used
  end

  def low_fuel_warning
    "Fuel level is low" if @fuel_level <= 5
  end
end
