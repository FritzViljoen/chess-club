class RecalculateStandings < Service
  def call
    people = Person.all.to_a
    contest_results = ContestResult.includes(:contest).to_a
    standings = CalculateStandings.call(people: people, contest_results: contest_results)

    WriteStandingsCache.call(standings: standings)
  end
end
