# One person's current position. Derived: WriteStandingsCache replaces every row
# from what CalculateStandings answered, and nothing else writes here.
class StandingsCache < ApplicationRecord
  self.table_name = "standings_cache"

  belongs_to :person
end
