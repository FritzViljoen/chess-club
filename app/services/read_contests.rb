class ReadContests < Service
  ORDERS = {
    "newest" => { played_at: :desc, id: :desc },
    "oldest" => { played_at: :asc, id: :asc }
  }.freeze

  SORTS = ORDERS.keys.freeze

  MATCHES = SearchTerm.matching("people.name", "people.surname").freeze

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
      return Contest.all if term.blank?

      Contest
        .joins(contest_results: :person)
        .where(MATCHES, term: term.anywhere)
        .distinct
    end

    def searching?
      term = SearchTerm.new(@query)

      !term.blank?
    end

    # Ids first: combining the filtered join with `includes` eager loads
    # through it, so each contest arrives holding only the matched participant.
    def rows(number)
      order = ORDERS.fetch(@sort)
      offset = Page.offset_for(number)

      narrowed = searching? ? Contest.where(id: found.select(:id)) : Contest.all

      narrowed
        .includes(contest_results: :person)
        .order(order)
        .limit(Page::SIZE)
        .offset(offset)
        .to_a
    end
end
