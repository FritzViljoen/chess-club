module LocalZone
  NAME = Rails.configuration.x.local_zone

  def self.zone
    ActiveSupport::TimeZone[NAME]
  end
end
