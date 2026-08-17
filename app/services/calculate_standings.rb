class CalculateStandings < Service
  def initialize(people:, contest_results:)
    @people = typed_array(people, Person)
    @contest_results = typed_array(contest_results, ContestResult)
  end

  def call
    ladder = Ladder.new(seed)

    contests.each do |results|
      ladder = apply(ladder, results)
    end

    numbered(ladder)
  end

  private
    def seed
      @people.sort_by { |person| [ person.joined_on, person.id ] }.map(&:id)
    end

    def contests
      @contest_results.group_by(&:contest_id).values.sort_by { |results| played(results) }
    end

    def played(results)
      [ results.first.contest.played_at, results.first.contest_id ]
    end

    def apply(ladder, results)
      higher, lower = results.sort_by { |result| ladder.position_of(result.person_id) }

      return ladder if higher.place < lower.place
      return tie(ladder, higher, lower) if higher.place == lower.place

      lower_ranked_won(ladder, higher, lower)
    end

    def tie(ladder, higher, lower)
      higher_at = ladder.position_of(higher.person_id)
      lower_at = ladder.position_of(lower.person_id)
      return ladder if lower_at - higher_at == 1

      ladder.moved(lower.person_id, to: lower_at - 1)
    end

    def lower_ranked_won(ladder, higher, lower)
      higher_at = ladder.position_of(higher.person_id)
      lower_at = ladder.position_of(lower.person_id)

      dropped = ladder.moved(higher.person_id, to: higher_at + 1)
      climb_to = lower_at - (lower_at - higher_at) / 2
      # At a gap of two both moves want the same position; the climb gives.
      return dropped if climb_to <= higher_at + 1

      dropped.moved(lower.person_id, to: climb_to)
    end

    def numbered(ladder)
      ladder.person_ids.map.with_index(1) do |person_id, position|
        Standing.new(person_id: person_id, position: position)
      end
    end
end
