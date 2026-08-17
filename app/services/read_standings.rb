class ReadStandings < Service
  def initialize(page:)
    @page = typed(page, Integer)
  end

  def call
    total = StandingsCache.count
    number = Page.number_for(wanted: @page, total: total)

    Page.new(rows: rows(number), number: number, total: total)
  end

  private
    def rows(number)
      StandingsCache
        .preload(:person)
        .left_joins(person: :contest_results)
        .group("standings_cache.id")
        .select("standings_cache.*, COUNT(contest_results.id) AS contest_results_count")
        .order(:position)
        .limit(Page::SIZE)
        .offset(Page.offset_for(number))
        .to_a
    end
end
