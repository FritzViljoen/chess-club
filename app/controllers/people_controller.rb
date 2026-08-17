class PeopleController < ApplicationController
  before_action :find_person, only: %i[ show edit update destroy ]

  def index
    @people = Person.order(:surname, :name)
  end

  def show
  end

  def new
    @person = Person.new
  end

  def edit
  end

  def create
    result = CreatePerson.call(**submitted)
    return redirect_to people_path, notice: "Added." if result.success?

    @person = Person.new(**submitted)
    @person.valid?
    render :new, status: :unprocessable_entity
  end

  def update
    result = UpdatePerson.call(person: @person, **submitted)
    return redirect_to people_path, notice: "Saved." if result.success?

    render :edit, status: :unprocessable_entity
  end

  def destroy
    RemovePerson.call(person: @person)

    redirect_to people_path, notice: "Removed."
  end

  private
    def find_person
      @person = Person.find(params[:id])
    end

    # The dates are read by the parsers, in the zone this application names, and
    # a value they cannot read bounces before any service is reached. They post
    # at the top level rather than nested, because that is where the parsers look.
    def submitted
      details = params.require(:person).permit(:name, :surname, :email)

      {
        name: details[:name].to_s,
        surname: details[:surname].to_s,
        email: details[:email].to_s,
        born_on: date_param!(:born_on, time_zone: LocalZone::NAME),
        joined_on: date_param!(:joined_on, time_zone: LocalZone::NAME)
      }
    end
end
