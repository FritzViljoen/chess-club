class Contest < ApplicationRecord
  PARTICIPANTS = 2

  # No `dependent:` — RemoveContest says what else goes.
  has_many :contest_results
  has_many :people, through: :contest_results

  validates :played_at, presence: true
  validate :two_different_people
  validate :somebody_finished_first
  validate :played_after_everybody_joined

  # A draw has no winner, so the two are separated by name rather than by which
  # was entered first — the order a reader sees should not depend on that.
  def in_place_order
    contest_results.sort_by { |result| [ result.place, result.person.surname, result.person.name ] }
  end

  def tie?
    contest_results.map(&:place).uniq.size == 1
  end

  def place(winner:, loser:, tie:)
    contest_results.build(person: winner, place: 1)
    contest_results.build(person: loser, place: tie ? 1 : 2)
  end

  private
    def two_different_people
      people_named = contest_results.map(&:person_id).uniq

      if contest_results.size != PARTICIPANTS
        errors.add(:contest_results, "must be exactly two")
      elsif people_named.size != PARTICIPANTS
        errors.add(:contest_results, "must name two different people")
      end
    end

    def somebody_finished_first
      return if contest_results.any? { |result| result.place == 1 }

      errors.add(:contest_results, "must include a first place")
    end

    def played_after_everybody_joined
      return if played_at.blank?

      played_on = played_at.in_time_zone(LocalZone::NAME).to_date
      return if contest_results.all? { |result| result.person.blank? || played_on >= result.person.joined_on }

      errors.add(:played_at, "cannot be before somebody joined")
    end
end
