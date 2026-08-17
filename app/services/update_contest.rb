class UpdateContest < Service
  def initialize(contest:, played_at:, winner:, loser:, tie:)
    @contest = typed(contest, Contest)
    @played_at = typed(played_at, ActiveSupport::TimeWithZone)
    @winner = typed(winner, Person)
    @loser = typed(loser, Person)
    @tie = typed(tie, Boolean)
  end

  def call
    ApplicationRecord.transaction do
      @contest.contest_results.destroy_all
      @contest.played_at = @played_at
      @contest.contest_results.build(person: @winner, place: 1)
      @contest.contest_results.build(person: @loser, place: @tie ? 1 : 2)
      return failure(:invalid) unless @contest.save

      RecalculateStandings.call
    end

    success(@contest)
  end
end
