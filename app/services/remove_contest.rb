class RemoveContest < Service
  def initialize(contest:)
    @contest = typed(contest, Contest)
  end

  def call
    ApplicationRecord.transaction do
      @contest.destroy!

      RecalculateStandings.call
    end

    success(@contest)
  end
end
