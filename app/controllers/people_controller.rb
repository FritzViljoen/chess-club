class PeopleController < ApplicationController
  def index
    @sort = enum_param(:sort, ReadPeople::SORTS, default: "name")
    @direction = enum_param(:dir, Listing::DIRECTIONS, default: ReadPeople::NATURAL.fetch(@sort))
    @query = text_param(:search)
    @listing = Listing.new(sort: @sort, direction: @direction, query: @query, natural: ReadPeople::NATURAL)
    @page = ReadPeople.call(sort: @sort, direction: @direction, page: integer_param(:page, default: 1), query: @query)
  end

  def show
    @person = requested_person
  end

  def new
    @person = Person.new
  end

  def edit
    @person = requested_person
  end

  def create
    @person = CreatePerson.call(**submitted)
    return redirect_to people_path, notice: "Added." if @person.errors.none?

    render :new, status: :unprocessable_entity
  end

  def update
    @person = requested_person
    UpdatePerson.call(person: @person, **submitted)
    return redirect_to people_path, notice: "Saved." if @person.errors.none?

    render :edit, status: :unprocessable_entity
  end

  def destroy
    RemovePerson.call(person: requested_person)

    redirect_to people_path, notice: "Removed."
  end

  private
    # Parsed, or Active Record coerces it and `/people/1abc` serves person 1.
    def requested_person
      Person.find(integer_param!(:id))
    end

    def submitted
      {
        name: text_param(:name),
        surname: text_param(:surname),
        email: text_param(:email),
        born_on: date_param!(:born_on, time_zone: LocalZone::NAME),
        joined_on: date_param!(:joined_on, time_zone: LocalZone::NAME)
      }
    end
end
