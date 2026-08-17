class Ladder
  include TypedArguments

  attr_reader :person_ids

  def initialize(person_ids)
    @person_ids = typed_array(person_ids, Integer)
  end

  def position_of(person_id)
    @person_ids.index(person_id) + 1
  end

  def moved(person_id, to:)
    remaining = @person_ids.dup
    remaining.delete(person_id)
    remaining.insert(to - 1, person_id)

    Ladder.new(remaining)
  end
end
