# One occasion on which people were placed against each other. Two today; the
# results are a collection so that more than two costs a validation change and
# not a migration.
class Contest < ApplicationRecord
  PARTICIPANTS = 2

  has_many :contest_results, dependent: :destroy
  has_many :people, through: :contest_results

  validates :played_at, presence: true
  validate :two_different_people
  validate :somebody_finished_first
  validate :played_after_everybody_joined

  private
    def two_different_people
      if contest_results.size != PARTICIPANTS
        errors.add(:contest_results, "must be exactly two")
      elsif contest_results.map(&:person_id).uniq.size != PARTICIPANTS
        errors.add(:contest_results, "must name two different people")
      end
    end

    def somebody_finished_first
      return if contest_results.any? { |result| result.place == 1 }

      errors.add(:contest_results, "must include a first place")
    end

    # The fold does not need this — seeding puts everybody in place before any
    # contest applies — but a contest predating a participant is bad data. The
    # day itself is early enough: somebody who joined this morning can play this
    # afternoon.
    def played_after_everybody_joined
      return if played_at.blank?

      played_on = played_at.in_time_zone(LocalZone::NAME).to_date
      return if contest_results.all? { |result| result.person.blank? || played_on >= result.person.joined_on }

      errors.add(:played_at, "cannot be before somebody joined")
    end
end
