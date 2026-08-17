ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Single process until there is a schema to fork on.
    #
    # Each parallel worker builds its own copy of the database from
    # db/schema.rb. There is no schema yet — no models, no migrations — so
    # forking workers hangs on a database that cannot be built, and it hangs
    # only once the suite passes Rails' 50-test threshold, which is a build
    # that breaks on the day an unrelated test is added. The suite today is
    # the house cops, which touch no database at all.
    #
    # Restore `workers: :number_of_processors` with the first migration.
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
