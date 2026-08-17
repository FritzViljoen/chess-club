class StandingsCache < ApplicationRecord
  self.table_name = "standings_cache"

  belongs_to :person
end
