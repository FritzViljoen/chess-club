class RemoveContest < Service
  def initialize(contest:)
    @contest = typed(contest, Contest)
  end

  def call
    ApplicationRecord.transaction do
      ContestResult.where(contest_id: @contest.id).delete_all
      @contest.destroy!

      RecalculateStandings.call
    end

    @contest
  end
end
