class UpdatePerson < Service
  def initialize(person:, name:, surname:, email:, born_on:, joined_on:)
    @person = typed(person, Person)
    @name = typed(name, String)
    @surname = typed(surname, String)
    @email = typed(email, String)
    @born_on = typed(born_on, Date)
    @joined_on = typed(joined_on, Date)
  end

  def call
    ApplicationRecord.transaction do
      updated = @person.update(
        name: @name, surname: @surname, email: @email,
        born_on: @born_on, joined_on: @joined_on
      )
      return failure(:invalid) unless updated

      RecalculateStandings.call
    end

    success(@person)
  end
end
