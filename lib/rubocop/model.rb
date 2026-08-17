# frozen_string_literal: true

# Loads every model cop, so .rubocop.yml requires this one file rather than
# listing the cops individually. Mirrors lib/rubocop/schema.rb.
Dir[File.expand_path("cop/model/*.rb", __dir__)].sort.each do |cop|
  require cop
end
