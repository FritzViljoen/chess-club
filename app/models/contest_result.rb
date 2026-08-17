class ContestResult < ApplicationRecord
  belongs_to :contest
  belongs_to :person

  validates :place, numericality: { only_integer: true, greater_than: 0 }
end
