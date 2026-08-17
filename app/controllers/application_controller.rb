class ApplicationController < ActionController::Base
  include TypedParams

  allow_browser versions: :modern

  stale_when_importmap_changes
end
