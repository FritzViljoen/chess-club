# Somebody the standings rank. Holds no ranking rule: a position is derived from
# the contest log by CalculateStandings, never stored here.
class Person < ApplicationRecord
  # Email is optional, and no column here is nullable — so "no email" is '' and
  # never NULL, one way to say it instead of two. The starting value lives here
  # because no column carries a database default.
  attribute :email, :string, default: ""

  has_many :contest_results, dependent: :destroy

  validates :name, :surname, :born_on, :joined_on, presence: true
  validates :email, uniqueness: true, allow_blank: true
end
