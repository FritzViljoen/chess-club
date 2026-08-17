class Page
  include TypedArguments

  SIZE = 10

  attr_reader :rows, :number, :total

  def initialize(rows:, number:, total:)
    @rows = typed(rows, Array)
    @number = typed(number, Integer)
    @total = typed(total, Integer)
  end

  def self.number_for(wanted:, total:)
    wanted.clamp(1, pages_for(total))
  end

  def self.offset_for(number)
    (number - 1) * SIZE
  end

  def self.pages_for(total)
    [ (total.to_f / SIZE).ceil, 1 ].max
  end

  def size
    SIZE
  end

  def pages
    Page.pages_for(total)
  end

  def first?
    number <= 1
  end

  def last?
    number >= pages
  end

  def previous
    number - 1
  end

  def following
    number + 1
  end

  def from
    return 0 if total.zero?

    Page.offset_for(number) + 1
  end

  def to
    [ number * SIZE, total ].min
  end
end
