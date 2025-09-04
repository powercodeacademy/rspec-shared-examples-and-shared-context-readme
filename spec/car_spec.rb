require_relative '../lib/car'


RSpec.describe Car do
  subject { Car.new("Toyota", "Corolla") }

  it_behaves_like "a vehicle that can start and stop"
  it_behaves_like "a wheeled vehicle", 4

  describe "fuel" do
    include_context "with a started vehicle"

    it "has a full tank when initialized" do
      expect(subject.fuel_level).to eq(100)
    end

    it "can be refueled" do
      subject.instance_variable_set(:@fuel_level, 20)
      subject.refuel
      expect(subject.fuel_level).to eq(100)
    end
    it "can drive a certain distance and reduce fuel" do
      subject.instance_variable_set(:@fuel_level, 20)
      subject.start
      subject.stop
      expect(subject.remaining_fuel(10)).to eq(15)  
    end

    it "warns when fuel is low" do
      subject.instance_variable_set(:@fuel_level, 3)
      expect(subject.low_fuel_warning).to eq("Fuel level is low")
    end
  end
end
