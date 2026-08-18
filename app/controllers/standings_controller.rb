class StandingsController < ApplicationController
  def show
    @listing = Listing.unsorted
    @page = ReadStandings.call(page: integer_param(:page, default: 1))
  end
end
