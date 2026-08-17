# A tie gives both people first place, so on a tie which one is named `winner`
# makes no difference to the outcome.
class CreateContest < Service
  def initialize(played_at:, winner:, loser:, tie:)
    @played_at = typed(played_at, ActiveSupport::TimeWithZone)
    @winner = typed(winner, Person)
    @loser = typed(loser, Person)
    @tie = typed(tie, Boolean)
  end

  def call
    contest = Contest.new(played_at: @played_at)
    contest.contest_results.build(person: @winner, place: 1)
    contest.contest_results.build(person: @loser, place: @tie ? 1 : 2)

    ApplicationRecord.transaction do
      return failure(:invalid) unless contest.save

      RecalculateStandings.call
    end

    success(contest)
  end
end
