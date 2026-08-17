# Base for every operation the application performs — reading or writing, one
# service per operation, one public method.
#
#   class ArchiveRound < Service
#     def initialize(round:)
#       @round = typed(round, Round)
#     end
#
#     def call
#       return failure(:already_archived) if @round.archived?
#
#       @round.archive!
#       success(@round)
#     end
#   end
#
# `call` must answer with a `Result` — `Service.call` raises `TypeError` on
# anything else, so a service cannot hand back whatever its last line evaluated
# to. A service that reads answers `success(rows)`, the same shape as one that
# writes.
#
# A refusal the caller can act on is `failure(:code)` — a code, not a sentence,
# because the wording belongs to whatever renders it. A defect raises.
#
# Reading and writing are separate services, never one with a flag. A change
# spanning records happens in one transaction.
class Service
  include TypedArguments

  # Nested here because it is this base's contract and nothing else's.
  Result = Struct.new(:value, :error) do
    def self.success(value)
      new(value, nil)
    end

    def self.failure(error)
      new(nil, error)
    end

    def success?
      error.nil?
    end
  end

  def self.call(**arguments)
    result = new(**arguments).call
    raise TypeError, "#{name}#call must return a Result" unless result.is_a?(Result)

    result
  end

  private
    # Shorthand, so a subclass need not reach for `Result` by name.
    def success(value = nil)
      Result.success(value)
    end

    def failure(error)
      Result.failure(error)
    end
end
