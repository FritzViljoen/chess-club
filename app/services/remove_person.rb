# A contest with one participant is not a contest, so the contests this person
# took part in go too. History naming a removed person does not survive them.
class RemovePerson < Service
  def initialize(person:)
    @person = typed(person, Person)
  end

  def call
    ApplicationRecord.transaction do
      Contest.where(id: @person.contest_results.select(:contest_id)).destroy_all
      @person.destroy!

      RecalculateStandings.call
    end

    success(@person)
  end
end
