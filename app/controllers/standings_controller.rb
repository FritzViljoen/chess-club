class StandingsController < ApplicationController
  def show
    @standings = ReadStandings.call.value
  end
end
