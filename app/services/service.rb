# `return` from inside a transaction block COMMITS it — abandon work with
# `raise ActiveRecord::Rollback`.
class Service
  include TypedArguments

  def self.call(**arguments)
    new(**arguments).call
  end
end
