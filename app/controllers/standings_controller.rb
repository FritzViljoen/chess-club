class StandingsController < ApplicationController
  def show
    @listing = Listing.new(sort: "", query: "")
    @page = ReadStandings.call(page: integer_param(:page, default: 1))
  end
end
