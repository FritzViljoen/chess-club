# Loads the whole log, calculates, and replaces the cache. Total every time: a
# few hundred rows folded in memory, and one code path that cannot disagree with
# itself.
#
# The contests are preloaded because CalculateStandings reads played_at off each
# result's contest and must not go looking for it a row at a time.
class RecalculateStandings < Service
  def call
    standings = CalculateStandings.call(
      people: Person.all.to_a,
      contest_results: ContestResult.includes(:contest).to_a
    ).value

    WriteStandingsCache.call(standings: standings)
  end
end
