class Listing
  include TypedArguments

  attr_reader :sort, :query

  def initialize(sort:, query:)
    @sort = typed(sort, String)
    @query = typed(query, String)
  end

  def showing(**overrides)
    { sort: sort, search: query }.compact_blank.merge(overrides)
  end

  def searching?
    query.present?
  end
end
