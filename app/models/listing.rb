class Listing
  include TypedArguments

  DIRECTIONS = %w[ asc desc ].freeze

  attr_reader :sort, :direction, :query

  # The leader board is the ranking — there is no column to sort it by.
  def self.unsorted
    new(sort: "", direction: "asc", query: "", natural: {})
  end

  def initialize(sort:, direction:, query:, natural:)
    @sort = typed(sort, String)
    @direction = typed_enum(direction, DIRECTIONS)
    @query = typed(query, String)
    @natural = typed_hash(natural, key: String, value: String)
  end

  def showing(**overrides)
    { sort: sort, dir: (direction if sort.present?), search: query }.compact_blank.merge(overrides)
  end

  def sorted_by?(key)
    sort == key
  end

  # Another column opens at its own natural direction rather than inheriting
  # this one's — a name list arriving Z-to-A because a count was sorted last is
  # not what was asked for.
  def turned(key)
    showing(sort: key, dir: sorted_by?(key) ? opposite : @natural.fetch(key))
  end

  def opposite
    direction == "asc" ? "desc" : "asc"
  end

  def searching?
    query.present?
  end
end
