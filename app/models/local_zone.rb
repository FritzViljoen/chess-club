# The one zone this application reads dates and times in. Named explicitly and in
# a single place: an ambient Time.zone is a zone nobody chose
# (constitution → `a-time-names-its-zone`).
module LocalZone
  NAME = "Africa/Johannesburg"

  def self.zone
    ActiveSupport::TimeZone[NAME]
  end
end
