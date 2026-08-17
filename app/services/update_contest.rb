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
      replace_results

      raise ActiveRecord::Rollback unless @contest.save
    end

    @contest
  end

  private
    def replace_results
      ContestResult.where(contest_id: @contest.id).delete_all
      @contest.contest_results.reset
      @contest.played_at = @played_at
      @contest.place(winner: @winner, loser: @loser, tie: @tie)
    end
end
