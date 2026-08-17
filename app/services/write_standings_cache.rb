# Replaces the derived standings with what somebody else calculated. It holds no
# rule: each Standing arrives naming its own position, so this does not know why
# the order is what it is, nor where the numbering starts.
class WriteStandingsCache < Service
  def initialize(standings:)
    @standings = typed_array(standings, Standing)
  end

  def call
    StandingsCache.delete_all
    StandingsCache.insert_all(rows) if rows.any?

    success(@standings)
  end

  private
    def rows
      @rows ||= @standings.map { |standing| { person_id: standing.person_id, position: standing.position } }
    end
end
