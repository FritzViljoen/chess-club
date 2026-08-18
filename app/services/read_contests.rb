class ReadContests < Service
  COLUMNS = {
    "played" => { by: %i[ played_at id ], natural: "desc" },
    "result" => { by: %i[ leader played_at ], natural: "asc" }
  }.freeze

  # The name a row leads with: the winner, and on a draw the first of the two by
  # surname — which is the order `Contest#in_place_order` renders them in.
  LEADER = "MIN(CASE WHEN contest_results.place = 1 THEN people.surname END)"

  SORTS = COLUMNS.keys.freeze

  NATURAL = COLUMNS.transform_values { |column| column.fetch(:natural) }.freeze

  MATCHES = SearchTerm.matching("people.name", "people.surname").freeze

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

    def order
      first, *tiebreak = COLUMNS.fetch(@sort).fetch(:by)

      { first => @direction.to_sym }.merge(tiebreak.index_with(@direction.to_sym))
    end

    # Two queries, because `includes` alongside the join and GROUP BY below eager
    # loads through them — each contest then arrives holding one participant.
    def rows(number)
      ids = ordered_ids(number)
      held = Contest.includes(contest_results: :person).where(id: ids).index_by(&:id)

      # `filter_map`, not `fetch`: a match removed between the two queries should
      # cost its row, not the whole page.
      ids.filter_map { |id| held[id] }
    end

    def ordered_ids(number)
      narrowed = searching? ? Contest.where(id: found.select(:id)) : Contest.all

      narrowed
        .left_joins(contest_results: :person)
        .group("contests.id")
        .select("contests.id, contests.played_at, #{LEADER} AS leader")
        .order(order)
        .limit(Page::SIZE)
        .offset(Page.offset_for(number))
        .map(&:id)
    end
end
