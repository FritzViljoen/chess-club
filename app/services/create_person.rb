class CreatePerson < Service
  def initialize(name:, surname:, email:, born_on:, joined_on:)
    @name = typed(name, String)
    @surname = typed(surname, String)
    @email = typed(email, String)
    @born_on = typed(born_on, Date)
    @joined_on = typed(joined_on, Date)
  end

  def call
    person = build

    ApplicationRecord.transaction do
      raise ActiveRecord::Rollback unless person.save

      RecalculateStandings.call
    end

    person
  end

  private
    def build
      Person.new(
        name: @name, surname: @surname, email: @email,
        born_on: @born_on, joined_on: @joined_on
      )
    end
end
