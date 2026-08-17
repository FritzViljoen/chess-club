class Standing
  include TypedArguments

  attr_reader :person_id, :position

  def initialize(person_id:, position:)
    @person_id = typed(person_id, Integer)
    @position = typed(position, Integer)
  end

  def ==(other)
    other.is_a?(Standing) && other.person_id == person_id && other.position == position
  end

  alias_method :eql?, :==

  def hash
    [ self.class, person_id, position ].hash
  end

  def inspect
    "#<Standing person_id: #{person_id}, position: #{position}>"
  end
end
