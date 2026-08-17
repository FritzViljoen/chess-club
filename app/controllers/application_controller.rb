class ApplicationController < ActionController::Base
  # Every date and time arriving over HTTP is parsed here and nowhere else.
  include TypedParams

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
