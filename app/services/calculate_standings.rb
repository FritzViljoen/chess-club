# Every ranking rule, and nothing else. Arrays in, an array of person ids out —
# no query, no write, so each rule is exercised by handing in two literals.
#
# `contest_results` arrive with their contest already loaded; this reads
# `played_at` off it and never goes back to the database for anything.
class CalculateStandings < Service
  def initialize(people:, contest_results:)
    @people = typed_array(people, Person)
    @contest_results = typed_array(contest_results, ContestResult)
  end

  def call
    success(numbered(contests.reduce(seed) { |order, results| apply(order, results) }))
  end

  private
    # The numbering is a rule like the rest — 1 is the top and the positions are
    # contiguous — so it is stated here rather than left for whoever writes the
    # rows to infer from their order.
    def numbered(order)
      order.each_with_index.map { |person_id, index| Standing[person_id: person_id, position: index + 1] }
    end

    # New people start last, so join order is the starting order.
    def seed
      @people.sort_by { |person| [ person.joined_on, person.id ] }.map(&:id)
    end

    # The results grouped into contests, oldest first. `contest_id` breaks a
    # shared moment: the fold has to be deterministic and two rows sharing one
    # have no other order.
    def contests
      @contest_results
        .group_by(&:contest_id)
        .values
        .sort_by { |results| [ results.first.contest.played_at, results.first.contest_id ] }
    end

    def apply(order, results)
      better, worse = results.sort_by { |result| order.index(result.person_id) }
      return order if better.place < worse.place

      a = order.index(better.person_id)
      b = order.index(worse.person_id)

      better.place == worse.place ? tie(order, b, b - a) : win_from_behind(order, a, b, b - a)
    end

    # The lower person gains one place, unless there is no room between them.
    def tie(order, b, gap)
      gap == 1 ? order : move(order, b, b - 1)
    end

    # The better-positioned person drops one place. The winner then climbs half
    # the gap, rounded down, measured from where both started.
    #
    # The two moves collide only at a gap of two, where both want the one slot
    # between the players. The drop is stated unconditionally by the brief and
    # the climb is already an approximation, so the climb is what gives.
    def win_from_behind(order, a, b, gap)
      dropped = move(order, a, a + 1)
      target = b - gap / 2

      target <= a + 1 ? dropped : move(dropped, dropped.index(order[b]), target)
    end

    # Everyone between the two indices shifts by one to fill in.
    def move(order, from, to)
      moved = order.dup
      moved.insert(to, moved.delete_at(from))
      moved
    end
end
