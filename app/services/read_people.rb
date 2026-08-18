class ReadPeople < Service
  # First column takes the asked-for direction; the rest are the tiebreak.
  COLUMNS = {
    "rank" => { by: %i[ position ], natural: "asc" },
    "name" => { by: %i[ surname name ], natural: "asc" },
    "email" => { by: %i[ email ], natural: "asc" },
    "joined" => { by: %i[ joined_on id ], natural: "asc" },
    "played" => { by: %i[ contest_results_count surname ], natural: "desc" }
  }.freeze

  SORTS = COLUMNS.keys.freeze

  NATURAL = COLUMNS.transform_values { |column| column.fetch(:natural) }.freeze

  MATCHES = SearchTerm.matching("name", "surname", "email").freeze

  def initialize(sort:, direction:, page:, query:)
    @sort = typed_enum(sort, SORTS)
    @direction = typed_enum(direction, Listing::DIRECTIONS)
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

    def order
      first, *tiebreak = COLUMNS.fetch(@sort).fetch(:by)

      { first => @direction.to_sym }.merge(tiebreak.index_with(:asc))
    end

    def rows(number)
      offset = Page.offset_for(number)

      found
        .left_joins(:contest_results, :standing_cache)
        .group(:id)
        .select("people.*, COUNT(contest_results.id) AS contest_results_count, MAX(standings_cache.position) AS position")
        .order(order)
        .limit(Page::SIZE)
        .offset(offset)
        .to_a
    end
end
