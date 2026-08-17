class WriteStandingsCache < Service
  def initialize(standings:)
    @standings = typed_array(standings, Standing)
  end

  def call
    rows = @standings.map { |standing| row(standing) }

    StandingsCache.delete_all
    StandingsCache.insert_all(rows) if rows.any?

    @standings
  end

  private
    def row(standing)
      { person_id: standing.person_id, position: standing.position }
    end
end
