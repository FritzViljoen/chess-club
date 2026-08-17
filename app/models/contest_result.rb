# Where one person finished in one contest. 1 is best; two results sharing a
# place are a tie.
class ContestResult < ApplicationRecord
  belongs_to :contest
  belongs_to :person

  validates :place, numericality: { only_integer: true, greater_than: 0 }
end
