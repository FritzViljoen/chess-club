class Person < ApplicationRecord
  # No `dependent:` — RemovePerson says what else goes.
  has_many :contest_results
  has_one :standing_cache, class_name: "StandingsCache"

  validates :name, :surname, :email, :born_on, :joined_on, presence: true
  validates :email, uniqueness: true

  def full_name
    "#{name} #{surname}"
  end
end
