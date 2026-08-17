class RemovePerson < Service
  def initialize(person:)
    @person = typed(person, Person)
  end

  def call
    ApplicationRecord.transaction do
      contest_ids = @person.contest_results.pluck(:contest_id)
      ContestResult.where(contest_id: contest_ids).delete_all
      Contest.where(id: contest_ids).delete_all
      @person.destroy!
    end

    @person
  end
end
