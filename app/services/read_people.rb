class ReadPeople < Service
  ORDERS = {
    "name" => { surname: :asc, name: :asc },
    "joined" => { joined_on: :asc, id: :asc },
    "played" => { contest_results_count: :desc, surname: :asc }
  }.freeze

  SORTS = ORDERS.keys.freeze

  MATCHES = SearchTerm.matching("name", "surname", "email").freeze

  def initialize(sort:, page:, query:)
    @sort = typed_enum(sort, SORTS)
    @page = typed(page, Integer)
    @query = typed(query, String)
  end

  def call
    total = found.count
    number = Page.number_for(wanted: @page, total: total)
    rows = rows(number)

    Page.new(rows: rows, number: number, total: total)
  end

  private
    def found
      term = SearchTerm.new(@query)
      return Person.all if term.blank?

      Person.where(MATCHES, term: term.anywhere)
    end

    def rows(number)
      order = ORDERS.fetch(@sort)
      offset = Page.offset_for(number)

      found
        .left_joins(:contest_results)
        .group(:id)
        .select("people.*, COUNT(contest_results.id) AS contest_results_count")
        .order(order)
        .limit(Page::SIZE)
        .offset(offset)
        .to_a
    end
end
