# frozen_string_literal: true

# Loads every schema cop, so .rubocop.yml requires this one file rather than
# listing the cops individually. The shared module goes first; the cops
# include it.
require_relative "cop/schema/column_definition"

Dir[File.expand_path("cop/schema/*.rb", __dir__)].sort.each do |cop|
  require cop
end
