# Somebody the standings rank. Holds no ranking rule: a position is derived from
# the contest log by CalculateStandings, never stored here.
#
# Email identifies a person from outside this database. The brief gives no number
# to use instead, and `id` is an implementation detail nobody outside would think
# to quote — so email is required and unique.
class Person < ApplicationRecord
  has_many :contest_results, dependent: :destroy

  validates :name, :surname, :email, :born_on, :joined_on, presence: true
  validates :email, uniqueness: true

  def full_name
    "#{name} #{surname}"
  end
end
