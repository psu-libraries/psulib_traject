class CallNumber

  attr_reader :value, :classification, :location

  def initialize(value:, classification:, location:)
    @value = value
    @classification = classification
    @location = location
  end

  def lop
    @value = lopped_value
  end

  private

  def lopped_value
    case classification
      when 'LC', 'LCPER'
        PsulibTraject::CallNumbers::LC.new(value).lopped
      when 'DEWEY'
        PsulibTraject::CallNumbers::Dewey.new(value).lopped
      else
        PsulibTraject::CallNumbers::Other.new(value).lopped
    end
  end

end
