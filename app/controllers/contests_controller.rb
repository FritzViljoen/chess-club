class ContestsController < ApplicationController
  before_action :find_contest, only: %i[ edit update destroy ]
  before_action :find_people, only: %i[ new edit create update ]

  def index
    @contests = Contest.includes(contest_results: :person).order(played_at: :desc, id: :desc)
  end

  def new
    @contest = Contest.new
  end

  def edit
  end

  def create
    result = CreateContest.call(**submitted)
    return redirect_to contests_path, notice: "Recorded." if result.success?

    @contest = Contest.new
    render :new, status: :unprocessable_entity
  end

  def update
    result = UpdateContest.call(contest: @contest, **submitted)
    return redirect_to contests_path, notice: "Saved." if result.success?

    render :edit, status: :unprocessable_entity
  end

  def destroy
    RemoveContest.call(contest: @contest)

    redirect_to contests_path, notice: "Removed."
  end

  private
    def find_contest
      @contest = Contest.find(params[:id])
    end

    def find_people
      @people = Person.order(:surname, :name)
    end

    def submitted
      details = params.require(:contest).permit(:winner_id, :loser_id)

      {
        played_at: time_param!(:played_at, time_zone: LocalZone::NAME),
        winner: Person.find(details[:winner_id]),
        loser: Person.find(details[:loser_id]),
        tie: boolean_param!(:tie)
      }
    end
end
