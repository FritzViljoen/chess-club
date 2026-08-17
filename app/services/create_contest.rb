class CreateContest < Service
  def initialize(played_at:, winner:, loser:, tie:)
    @played_at = typed(played_at, ActiveSupport::TimeWithZone)
    @winner = typed(winner, Person)
    @loser = typed(loser, Person)
    @tie = typed(tie, Boolean)
  end

  def call
    contest = build

    ApplicationRecord.transaction do
      raise ActiveRecord::Rollback unless contest.save
    end

    contest
  end

  private
    def build
      contest = Contest.new(played_at: @played_at)
      contest.place(winner: @winner, loser: @loser, tie: @tie)

      contest
    end
end
