# Reads the derived standings for the one page that shows them. An empty
# standings is an answer, not a refusal.
class ReadStandings < Service
  def call
    success(StandingsCache.includes(person: :contest_results).order(:position).to_a)
  end
end
