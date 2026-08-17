class ContestsController < ApplicationController
  def index
    @sort = enum_param(:sort, ReadContests::SORTS, default: "newest")
    @query = text_param(:search)
    @listing = Listing.new(sort: @sort, query: @query)
    @page = ReadContests.call(sort: @sort, page: integer_param(:page, default: 1), query: @query)
  end

  def new
    @contest = Contest.new
    @people = choosable_people
  end

  def edit
    @contest = requested_contest
    @people = choosable_people
  end

  def create
    @contest = CreateContest.call(**submitted)
    return redirect_to contests_path, notice: "Recorded." if @contest.errors.none?

    @people = choosable_people
    render :new, status: :unprocessable_entity
  end

  def update
    @contest = requested_contest
    UpdateContest.call(contest: @contest, **submitted)
    return redirect_to contests_path, notice: "Saved." if @contest.errors.none?

    @people = choosable_people
    render :edit, status: :unprocessable_entity
  end

  def destroy
    RemoveContest.call(contest: requested_contest)

    redirect_to contests_path, notice: "Removed."
  end

  private
    def requested_contest
      Contest.includes(contest_results: :person).find(integer_param!(:id))
    end

    def choosable_people
      Person.order(:surname, :name)
    end

    def submitted
      {
        played_at: time_param!(:played_at, time_zone: LocalZone::NAME),
        winner: person(integer_param!(:winner_id)),
        loser: person(integer_param!(:loser_id)),
        tie: boolean_param!(:tie)
      }
    end

    def person(id)
      Person.find_by(id: id) || raise(TypedParams::BadParam, :player)
    end
end
